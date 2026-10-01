import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service.dart';
import '../../l10n/perfil_negocio_texts.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../admin/admin_navigation_shell.dart';
import '../admin/admin_portal_components.dart';
import '../admin/admin_portal_texts.dart';
import '../admin/admin_visual_assets_catalog.dart';

class AdminVisualAssetsWebPage extends StatefulWidget {
  const AdminVisualAssetsWebPage({super.key});

  @override
  State<AdminVisualAssetsWebPage> createState() =>
      _AdminVisualAssetsWebPageState();
}

class _AdminVisualAssetsWebPageState extends State<AdminVisualAssetsWebPage> {
  static const String _semSubsegmento = '__SEM_SUBSEGMENTO__';

  final AuthService _authService = AuthService();
  final TextEditingController _buscaController = TextEditingController();

  bool _verificandoAcesso = true;
  bool _saindo = false;
  String? _userName;
  String? _userEmail;
  String? _segmento;
  String? _subsegmento;
  AdminVisualAssetSlot? _slot;
  AdminVisualAssetStatus? _status;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
    WidgetsBinding.instance.addPostFrameCallback((_) => _validarSuper());
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _validarSuper() async {
    final ColaboradorAutorizacoesProvider provider =
        context.read<ColaboradorAutorizacoesProvider>();
    await provider.carregarAutorizacoesDoUsuarioLogado(force: true);
    if (!mounted) return;

    if (!provider.ehSuperUsuario) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/app', (Route<dynamic> route) => false);
      return;
    }

    setState(() => _verificandoAcesso = false);
  }

  Future<void> _carregarUsuario() async {
    final String? email = await _authService.getUserEmail();
    if (!mounted) return;
    setState(() {
      _userEmail = email;
      _userName = _nomeExibicaoPorEmail(email);
    });
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

  void _limparFiltros() {
    _buscaController.clear();
    setState(() {
      _segmento = null;
      _subsegmento = null;
      _slot = null;
      _status = null;
    });
  }

  List<AdminVisualAssetRecord> get _filtrados {
    final String busca = _buscaController.text.trim().toLowerCase();

    return AdminVisualAssetsCatalog.records.where((record) {
      if (_segmento != null && record.contexto.segmento != _segmento) {
        return false;
      }
      if (_subsegmento != null) {
        if (_subsegmento == _semSubsegmento) {
          if (record.contexto.subsegmento != null) return false;
        } else if (record.contexto.subsegmento != _subsegmento) {
          return false;
        }
      }
      if (_slot != null && record.slot != _slot) return false;
      if (_status != null && record.status != _status) return false;

      if (busca.isEmpty) return true;
      final String haystack = <String>[
        record.contexto.segmento,
        record.contexto.subsegmento ?? '',
        record.slot.name,
        record.profileFolder ?? '',
        record.imageUrl ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(busca);
    }).toList(growable: false);
  }

  int get _disponiveis => AdminVisualAssetsCatalog.records
      .where((record) => record.status == AdminVisualAssetStatus.disponivel)
      .length;

  int get _planejados => AdminVisualAssetsCatalog.records.length - _disponiveis;

  @override
  Widget build(BuildContext context) {
    final _VisualAssetsTexts texts = _VisualAssetsTexts.of(context);

    if (_verificandoAcesso) {
      return Scaffold(
        backgroundColor: AdminPalette.background,
        body: Center(
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
        ),
      );
    }

    final ColaboradorAutorizacoesProvider autorizacoes =
        context.watch<ColaboradorAutorizacoesProvider>();
    if (!autorizacoes.ehSuperUsuario) {
      return const SizedBox.shrink();
    }

    final AdminPortalTexts portalTexts = AdminPortalTexts.of(context);
    final List<AdminVisualAssetRecord> records = _filtrados;

    return AdminNavigationShell(
      texts: portalTexts,
      userInfo: AdminPortalUserInfo(
        name: _userName,
        email: _userEmail,
        profileType: autorizacoes.tipoPerfilUnificado,
      ),
      currentRoute: '/admin/imagens-contextuais',
      pageTitle: texts.title,
      onLogout: _logout,
      onRefresh: () => setState(() {}),
      refreshing: false,
      loggingOut: _saindo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHeader(texts, records),
          const SizedBox(height: AdminSpacing.lg),
          _buildFilters(texts),
          const SizedBox(height: AdminSpacing.lg),
          _buildLegend(texts),
          const SizedBox(height: AdminSpacing.lg),
          if (records.isEmpty)
            _buildEmpty(texts)
          else
            _buildGrid(texts, records),
        ],
      ),
    );
  }

  Widget _buildHeader(
    _VisualAssetsTexts texts,
    List<AdminVisualAssetRecord> records,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 760;
        final Widget intro = Column(
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
              texts.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AdminPalette.dark,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Text(
                texts.subtitle,
                style: const TextStyle(
                  color: AdminPalette.bodyText,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ),
          ],
        );

        final Widget counters = Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: compact ? WrapAlignment.start : WrapAlignment.end,
          children: <Widget>[
            _SummaryPill(
              icon: Icons.filter_alt_rounded,
              label: texts.filtered,
              value: records.length.toString(),
            ),
            _SummaryPill(
              icon: Icons.image_rounded,
              label: texts.available,
              value: _disponiveis.toString(),
              emphasized: true,
            ),
            _SummaryPill(
              icon: Icons.hourglass_empty_rounded,
              label: texts.planned,
              value: _planejados.toString(),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              intro,
              const SizedBox(height: 18),
              counters,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(child: intro),
            const SizedBox(width: 24),
            Flexible(child: counters),
          ],
        );
      },
    );
  }

  Widget _buildFilters(_VisualAssetsTexts texts) {
    final List<String> subsegmentos =
        AdminVisualAssetsCatalog.subsegmentosDe(_segmento);

    return Container(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        border: Border.all(color: AdminPalette.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.tune_rounded, color: AdminPalette.dark),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  texts.filters,
                  style: const TextStyle(
                    color: AdminPalette.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _limparFiltros,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                label: Text(texts.clearFilters),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 820;
              final double width =
                  compact
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 36) / 4;

              final List<Widget> filters = <Widget>[
                SizedBox(
                  width: width,
                  child: _FilterSelect<String>(
                    label: texts.segment,
                    value: _segmento,
                    placeholder: texts.all,
                    items:
                        AdminVisualAssetsCatalog.segmentos.keys
                            .map(
                              (String code) => _FilterOption<String>(
                                value: code,
                                label: perfilNegocioText(
                                  context,
                                  'segment.$code',
                                ),
                              ),
                            )
                            .toList(growable: false),
                    onChanged: (String? value) {
                      setState(() {
                        _segmento = value;
                        _subsegmento = null;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _FilterSelect<String>(
                    label: texts.specialty,
                    value: _subsegmento,
                    placeholder: texts.all,
                    enabled: _segmento != null,
                    items: <_FilterOption<String>>[
                      _FilterOption<String>(
                        value: _semSubsegmento,
                        label: texts.noSpecialty,
                      ),
                      ...subsegmentos.map(
                        (String code) => _FilterOption<String>(
                          value: code,
                          label: perfilNegocioText(context, 'sub.$code'),
                        ),
                      ),
                    ],
                    onChanged: (String? value) {
                      setState(() => _subsegmento = value);
                    },
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _FilterSelect<AdminVisualAssetSlot>(
                    label: texts.cta,
                    value: _slot,
                    placeholder: texts.all,
                    items:
                        AdminVisualAssetSlot.values
                            .map(
                              (AdminVisualAssetSlot slot) =>
                                  _FilterOption<AdminVisualAssetSlot>(
                                    value: slot,
                                    label: texts.slot(slot),
                                  ),
                            )
                            .toList(growable: false),
                    onChanged: (AdminVisualAssetSlot? value) {
                      setState(() => _slot = value);
                    },
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _FilterSelect<AdminVisualAssetStatus>(
                    label: texts.status,
                    value: _status,
                    placeholder: texts.all,
                    items:
                        AdminVisualAssetStatus.values
                            .map(
                              (AdminVisualAssetStatus status) =>
                                  _FilterOption<AdminVisualAssetStatus>(
                                    value: status,
                                    label: texts.statusLabel(status),
                                  ),
                            )
                            .toList(growable: false),
                    onChanged: (AdminVisualAssetStatus? value) {
                      setState(() => _status = value);
                    },
                  ),
                ),
              ];

              return Wrap(spacing: 12, runSpacing: 12, children: filters);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _buscaController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: texts.searchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon:
                  _buscaController.text.isEmpty
                      ? null
                      : IconButton(
                        tooltip: texts.clearSearch,
                        onPressed: () {
                          _buscaController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              filled: true,
              fillColor: AdminPalette.softSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AdminRadius.md),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AdminRadius.md),
                borderSide: const BorderSide(color: AdminPalette.border),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(_VisualAssetsTexts texts) {
    return AdminSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.lg),
        child: Wrap(
          spacing: 18,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(
              texts.screenLabel,
              style: const TextStyle(
                color: AdminPalette.dark,
                fontWeight: FontWeight.w900,
              ),
            ),
            _StatusChip(
              icon: Icons.phone_iphone_rounded,
              label: texts.mobileAttendance,
              tone: _ChipTone.neutral,
            ),
            _StatusChip(
              icon: Icons.crop_free_rounded,
              label: texts.fullCard,
              tone: _ChipTone.success,
            ),
            _StatusChip(
              icon: Icons.widgets_outlined,
              label: texts.contextualIcon,
              tone: _ChipTone.info,
            ),
            _StatusChip(
              icon: Icons.hourglass_empty_rounded,
              label: texts.notCreatedYet,
              tone: _ChipTone.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(
    _VisualAssetsTexts texts,
    List<AdminVisualAssetRecord> records,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns =
            constraints.maxWidth >= 1180
                ? 4
                : constraints.maxWidth >= 860
                ? 3
                : constraints.maxWidth >= 560
                ? 2
                : 1;
        final double gap = 14;
        final double width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children:
              records
                  .map(
                    (AdminVisualAssetRecord record) => SizedBox(
                      width: width,
                      child: _AssetCard(record: record, texts: texts),
                    ),
                  )
                  .toList(growable: false),
        );
      },
    );
  }

  Widget _buildEmpty(_VisualAssetsTexts texts) {
    return AdminSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.image_search_rounded,
              size: 42,
              color: AdminPalette.mutedText,
            ),
            const SizedBox(height: 14),
            Text(
              texts.emptyTitle,
              style: const TextStyle(
                color: AdminPalette.dark,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              texts.emptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AdminPalette.bodyText),
            ),
          ],
        ),
      ),
    );
  }

  String? _nomeExibicaoPorEmail(String? email) {
    final String normalized = email?.trim() ?? '';
    if (normalized.isEmpty || !normalized.contains('@')) return null;
    final String prefix =
        normalized
            .split('@')
            .first
            .replaceAll('.', ' ')
            .replaceAll('_', ' ')
            .trim();
    if (prefix.isEmpty) return null;
    return prefix
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .map(
          (String part) =>
              '${part.characters.first.toUpperCase()}${part.characters.skip(1).join().toLowerCase()}',
        )
        .join(' ');
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({required this.record, required this.texts});

  final AdminVisualAssetRecord record;
  final _VisualAssetsTexts texts;

  @override
  Widget build(BuildContext context) {
    final bool available = record.status == AdminVisualAssetStatus.disponivel;
    final String title = perfilNegocioText(
      context,
      'segment.${record.contexto.segmento}',
    );
    final String specialty =
        record.contexto.subsegmento == null
            ? texts.noSpecialty
            : perfilNegocioText(
              context,
              'sub.${record.contexto.subsegmento}',
            );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        border: Border.all(color: AdminPalette.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 4 / 5,
            child:
                available && record.imageUrl != null
                    ? Image.network(
                      record.imageUrl!,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder:
                          (_, __, ___) => _AssetPlaceholder(
                            icon: Icons.broken_image_outlined,
                            label: texts.imageError,
                            available: false,
                          ),
                    )
                    : _AssetPlaceholder(
                      icon: Icons.add_photo_alternate_outlined,
                      label: texts.notCreatedYet,
                      available: false,
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        texts.slot(record.slot),
                        style: const TextStyle(
                          color: AdminPalette.dark,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      icon:
                          available
                              ? Icons.check_circle_rounded
                              : Icons.schedule_rounded,
                      label: texts.statusLabel(record.status),
                      tone:
                          available
                              ? _ChipTone.success
                              : _ChipTone.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: AdminPalette.dark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  specialty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminPalette.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: <Widget>[
                    _StatusChip(
                      icon: Icons.phone_iphone_rounded,
                      label: texts.mobile,
                      tone: _ChipTone.neutral,
                    ),
                    if (available)
                      _StatusChip(
                        icon:
                            record.fullCard
                                ? Icons.crop_free_rounded
                                : Icons.widgets_outlined,
                        label:
                            record.fullCard
                                ? texts.fullCard
                                : texts.contextualIcon,
                        tone:
                            record.fullCard
                                ? _ChipTone.success
                                : _ChipTone.info,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (available && record.imageUrl != null) ...<Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AdminPalette.softSurface,
                      borderRadius: BorderRadius.circular(AdminRadius.md),
                    ),
                    child: SelectableText(
                      record.imageUrl!,
                      maxLines: 3,
                      style: const TextStyle(
                        color: AdminPalette.bodyText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: record.imageUrl!),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(texts.copied)),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 17),
                          label: Text(texts.copyUrl),
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    texts.plannedHint,
                    style: const TextStyle(
                      color: AdminPalette.bodyText,
                      fontSize: 12,
                      height: 1.4,
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

class _AssetPlaceholder extends StatelessWidget {
  const _AssetPlaceholder({
    required this.icon,
    required this.label,
    required this.available,
  });

  final IconData icon;
  final String label;
  final bool available;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AdminPalette.softSurface,
            Color(0xFFE8EEF6),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 38, color: AdminPalette.mutedText),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AdminPalette.mutedText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color:
            emphasized ? AdminPalette.activeGreen : AdminPalette.softSurface,
        borderRadius: BorderRadius.circular(AdminRadius.md),
        border: Border.all(
          color:
              emphasized
                  ? AdminPalette.activeGreen
                  : AdminPalette.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 17, color: AdminPalette.dark),
          const SizedBox(width: 7),
          Text(
            '$label: $value',
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

enum _ChipTone { neutral, success, info, warning }

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (tone) {
      _ChipTone.success => (AdminPalette.activeGreen, AdminPalette.dark),
      _ChipTone.info => (
        const Color(0xFFE8F1FF),
        const Color(0xFF145BFF),
      ),
      _ChipTone.warning => (
        const Color(0xFFFFF2D9),
        const Color(0xFF8A5A00),
      ),
      _ChipTone.neutral => (
        AdminPalette.softSurface,
        AdminPalette.bodyText,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption<T> {
  const _FilterOption({required this.value, required this.label});

  final T value;
  final String label;
}

class _FilterSelect<T> extends StatelessWidget {
  const _FilterSelect({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final T? value;
  final String placeholder;
  final List<_FilterOption<T>> items;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final _FilterOption<T>? selected =
        value == null
            ? null
            : items.cast<_FilterOption<T>?>().firstWhere(
              (_FilterOption<T>? item) => item?.value == value,
              orElse: () => null,
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: AdminPalette.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        PopupMenuButton<T?>(
          enabled: enabled,
          tooltip: label,
          onSelected: onChanged,
          itemBuilder:
              (BuildContext context) => <PopupMenuEntry<T?>>[
                PopupMenuItem<T?>(
                  value: null,
                  child: Row(
                    children: <Widget>[
                      Icon(
                        value == null
                            ? Icons.check_rounded
                            : Icons.circle_outlined,
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Text(placeholder),
                    ],
                  ),
                ),
                ...items.map(
                  (_FilterOption<T> item) => PopupMenuItem<T?>(
                    value: item.value,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          value == item.value
                              ? Icons.check_rounded
                              : Icons.circle_outlined,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item.label)),
                      ],
                    ),
                  ),
                ),
              ],
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: AdminPalette.softSurface,
                borderRadius: BorderRadius.circular(AdminRadius.md),
                border: Border.all(color: AdminPalette.border),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      selected?.label ?? placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminPalette.dark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AdminPalette.mutedText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VisualAssetsTexts {
  const _VisualAssetsTexts(this.language);
  final String language;

  factory _VisualAssetsTexts.of(BuildContext context) =>
      _VisualAssetsTexts(Localizations.localeOf(context).languageCode);

  String _pick(String pt, String en, String es) =>
      language == 'en'
          ? en
          : language == 'es'
          ? es
          : pt;

  String get checkingAccess => _pick(
    'Verificando acesso SUPER…',
    'Checking SUPER access…',
    'Verificando acceso SUPER…',
  );
  String get eyebrow => _pick(
    'Biblioteca visual',
    'Visual library',
    'Biblioteca visual',
  );
  String get title => _pick(
    'Imagens contextuais',
    'Contextual images',
    'Imágenes contextuales',
  );
  String get subtitle => _pick(
    'Consulte o que o SixApp exibe hoje para cada perfil de negócio e identifique combinações que ainda precisam de arte.',
    'See what SixApp currently displays for each business profile and identify combinations that still need artwork.',
    'Consulta lo que SixApp muestra hoy para cada perfil de negocio e identifica combinaciones que aún necesitan imágenes.',
  );
  String get filters => _pick('Filtros de contexto', 'Context filters', 'Filtros de contexto');
  String get clearFilters => _pick('Limpar filtros', 'Clear filters', 'Limpiar filtros');
  String get filtered => _pick('Exibidos', 'Shown', 'Mostrados');
  String get available => _pick('Com imagem', 'With image', 'Con imagen');
  String get planned => _pick('Sem imagem', 'Without image', 'Sin imagen');
  String get all => _pick('Todos', 'All', 'Todos');
  String get segment => _pick('Segmento', 'Business segment', 'Segmento');
  String get specialty => _pick('Especialidade', 'Specialty', 'Especialidad');
  String get noSpecialty => _pick('Sem especialidade', 'No specialty', 'Sin especialidad');
  String get cta => 'CTA';
  String get status => _pick('Situação', 'Status', 'Estado');
  String get searchHint => _pick(
    'Buscar por código, pasta ou URL…',
    'Search by code, folder or URL…',
    'Buscar por código, carpeta o URL…',
  );
  String get clearSearch => _pick('Limpar busca', 'Clear search', 'Limpiar búsqueda');
  String get screenLabel => _pick('Tela atual:', 'Current screen:', 'Pantalla actual:');
  String get mobileAttendance => _pick('Atendimento Mobile', 'Mobile Service', 'Atención Mobile');
  String get fullCard => 'Full-card';
  String get contextualIcon => _pick('Imagem contextual atual', 'Current contextual image', 'Imagen contextual actual');
  String get notCreatedYet => _pick('Ainda sem imagem', 'No image yet', 'Aún sin imagen');
  String get mobile => 'Mobile';
  String get imageError => _pick('Imagem indisponível', 'Image unavailable', 'Imagen no disponible');
  String get copyUrl => _pick('Copiar URL', 'Copy URL', 'Copiar URL');
  String get copied => _pick('URL copiada.', 'URL copied.', 'URL copiada.');
  String get plannedHint => _pick(
    'Esta combinação está mapeada como lacuna: o app usa o fallback local até uma nova arte ser criada e associada.',
    'This combination is mapped as a gap: the app uses its local fallback until new artwork is created and assigned.',
    'Esta combinación está registrada como pendiente: la app usa el fallback local hasta crear y asociar una nueva imagen.',
  );
  String get emptyTitle => _pick('Nenhuma combinação encontrada', 'No combination found', 'No se encontró ninguna combinación');
  String get emptySubtitle => _pick('Ajuste os filtros ou limpe a busca.', 'Adjust the filters or clear the search.', 'Ajusta los filtros o limpia la búsqueda.');

  String slot(AdminVisualAssetSlot slot) {
    return switch (slot) {
      AdminVisualAssetSlot.vendas => _pick('Vendas', 'Sales', 'Ventas'),
      AdminVisualAssetSlot.servicos => _pick('Serviços', 'Services', 'Servicios'),
      AdminVisualAssetSlot.receber => _pick('Receber', 'Receive', 'Cobrar'),
      AdminVisualAssetSlot.operacoesCaixa => _pick('Operações de caixa', 'Cash operations', 'Operaciones de caja'),
      AdminVisualAssetSlot.devolucao => _pick('Devolução', 'Returns', 'Devolución'),
    };
  }

  String statusLabel(AdminVisualAssetStatus status) {
    return switch (status) {
      AdminVisualAssetStatus.disponivel => _pick('Disponível', 'Available', 'Disponible'),
      AdminVisualAssetStatus.planejado => _pick('Planejado', 'Planned', 'Planificado'),
    };
  }
}
