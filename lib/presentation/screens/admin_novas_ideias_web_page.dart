import 'package:flutter/material.dart';

import '../../core/services/admin_ideas_service.dart';
import '../../core/services/auth_service.dart';
import '../admin/admin_navigation_shell.dart';
import '../admin/admin_portal_components.dart';
import '../admin/admin_portal_texts.dart';

class AdminNovasIdeiasWebPage extends StatefulWidget {
  const AdminNovasIdeiasWebPage({super.key});

  @override
  State<AdminNovasIdeiasWebPage> createState() => _AdminNovasIdeiasWebPageState();
}

class _AdminNovasIdeiasWebPageState extends State<AdminNovasIdeiasWebPage> {
  final AdminIdeasService _service = AdminIdeasService();
  final AuthService _authService = AuthService();
  final TextEditingController _filtroController = TextEditingController();

  bool _carregando = true;
  bool _saindo = false;
  String? _erro;
  String? _userName;
  String? _userEmail;
  String? _profileType;
  List<AdminIdeaModel> _ideias = const <AdminIdeaModel>[];

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
    _carregar();
  }

  @override
  void dispose() {
    _filtroController.dispose();
    super.dispose();
  }

  Future<void> _carregarUsuario() async {
    final String? email = await _authService.getUserEmail();
    final String profileType = await _authService.getUserProfileType();
    if (!mounted) return;
    setState(() {
      _userEmail = email;
      _profileType = profileType;
      _userName = _nomeExibicaoPorEmail(email);
    });
  }

  Future<void> _carregar() async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      final List<AdminIdeaModel> ideias = await _service.listar();
      if (!mounted) return;
      setState(() {
        _ideias = ideias;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      final String mensagem = e.toString().replaceAll('Exception: ', '');
      if (_erroDeSessao(mensagem)) {
        Navigator.of(context).pushNamedAndRemoveUntil('/admin', (Route<dynamic> route) => false);
        return;
      }
      setState(() {
        _erro = mensagem;
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
      Navigator.of(context).pushNamedAndRemoveUntil('/admin', (Route<dynamic> route) => false);
    }
  }

  bool _erroDeSessao(String mensagem) {
    final String normalized = mensagem.toLowerCase();
    return normalized.contains('login') || normalized.contains('sessão') || normalized.contains('sessao');
  }

  String? _nomeExibicaoPorEmail(String? email) {
    final String normalized = email?.trim() ?? '';
    if (normalized.isEmpty || !normalized.contains('@')) return null;
    final String prefix = normalized.split('@').first.replaceAll('.', ' ').replaceAll('_', ' ').trim();
    if (prefix.isEmpty) return null;
    return prefix
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .map((String part) => '${part.characters.first.toUpperCase()}${part.characters.skip(1).join().toLowerCase()}')
        .join(' ');
  }

  List<AdminIdeaModel> get _filtradas {
    final String filtro = _filtroController.text.trim().toLowerCase();
    if (filtro.isEmpty) return _ideias;
    return _ideias.where((AdminIdeaModel idea) {
      return idea.descricao.toLowerCase().contains(filtro) ||
          idea.modulo.toLowerCase().contains(filtro) ||
          idea.telaAtual.toLowerCase().contains(filtro) ||
          idea.plataforma.toLowerCase().contains(filtro) ||
          idea.idioma.toLowerCase().contains(filtro) ||
          idea.status.toLowerCase().contains(filtro) ||
          idea.empresaId.toLowerCase().contains(filtro);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final AdminPortalTexts portalTexts = AdminPortalTexts.of(context);
    final _IdeasTexts texts = _IdeasTexts.of(context);

    return AdminNavigationShell(
      texts: portalTexts,
      userInfo: AdminPortalUserInfo(name: _userName, email: _userEmail, profileType: _profileType),
      currentRoute: '/admin/novas-ideias',
      pageTitle: texts.title,
      onLogout: _logout,
      onRefresh: _carregar,
      refreshing: _carregando,
      loggingOut: _saindo,
      child: AnimatedSwitcher(
        duration: AdminMotion.medium,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _buildContent(texts),
      ),
    );
  }

  Widget _buildContent(_IdeasTexts texts) {
    if (_carregando) {
      return _IdeasLoadingState(key: const ValueKey<String>('ideas-loading'), texts: texts);
    }

    final String? erro = _erro;
    if (erro != null) {
      return _IdeasErrorState(
        key: const ValueKey<String>('ideas-error'),
        texts: texts,
        message: erro,
        onRetry: _carregar,
      );
    }

    final List<AdminIdeaModel> ideas = _filtradas;
    return Column(
      key: ValueKey<String>('ideas-${ideas.length}-${_ideias.length}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _IdeasHeader(texts: texts, total: _ideias.length, visible: ideas.length),
        const SizedBox(height: AdminSpacing.lg),
        _IdeasFilter(
          controller: _filtroController,
          hint: texts.search,
          onChanged: (_) => setState(() {}),
          onClear: () {
            _filtroController.clear();
            setState(() {});
          },
        ),
        const SizedBox(height: AdminSpacing.lg),
        if (ideas.isEmpty)
          _IdeasEmptyState(texts: texts, hasFilter: _filtroController.text.trim().isNotEmpty)
        else
          ...ideas.map((AdminIdeaModel idea) => Padding(
                padding: const EdgeInsets.only(bottom: AdminSpacing.md),
                child: _IdeaCard(idea: idea, texts: texts),
              )),
      ],
    );
  }
}

class _IdeasHeader extends StatelessWidget {
  const _IdeasHeader({required this.texts, required this.total, required this.visible});

  final _IdeasTexts texts;
  final int total;
  final int visible;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 680;
        final Widget counter = Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AdminPalette.activeGreen,
            borderRadius: BorderRadius.circular(AdminRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.lightbulb_rounded, size: 18, color: AdminPalette.dark),
              const SizedBox(width: 8),
              Text(
                visible == total ? '$total ${texts.records}' : '$visible ${texts.ofLabel} $total',
                style: const TextStyle(fontWeight: FontWeight.w900, color: AdminPalette.dark),
              ),
            ],
          ),
        );

        final Widget title = Column(
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
                    letterSpacing: -0.8,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              texts.subtitle,
              style: const TextStyle(
                color: AdminPalette.bodyText,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              title,
              const SizedBox(height: 16),
              counter,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(child: title),
            const SizedBox(width: 20),
            counter,
          ],
        );
      },
    );
  }
}

class _IdeasFilter extends StatelessWidget {
  const _IdeasFilter({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        border: Border.all(color: AdminPalette.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                  onPressed: onClear,
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
    );
  }
}

class _IdeaCard extends StatelessWidget {
  const _IdeaCard({required this.idea, required this.texts});

  final AdminIdeaModel idea;
  final _IdeasTexts texts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        border: Border.all(color: AdminPalette.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x09000000), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AdminPalette.activeGreen,
                  borderRadius: BorderRadius.circular(AdminRadius.md),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded, color: AdminPalette.dark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  idea.descricao,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AdminPalette.dark,
                        height: 1.35,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(status: idea.status),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AdminPalette.border),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _InfoTag(icon: Icons.widgets_outlined, label: texts.module, value: idea.modulo),
              _InfoTag(icon: Icons.web_asset_outlined, label: texts.screen, value: idea.telaAtual),
              _InfoTag(icon: Icons.devices_rounded, label: texts.platform, value: idea.plataforma),
              _InfoTag(icon: Icons.language_rounded, label: texts.language, value: idea.idioma),
              _InfoTag(icon: Icons.business_outlined, label: texts.company, value: idea.empresaId),
              _InfoTag(icon: Icons.schedule_rounded, label: texts.receivedAt, value: _formatDate(idea.criadaEm)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final DateTime local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final String normalized = status.trim().isEmpty ? 'RECEBIDA' : status.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AdminPalette.softSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Text(
        normalized.replaceAll('_', ' '),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AdminPalette.dark,
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AdminPalette.softSurface,
        borderRadius: BorderRadius.circular(AdminRadius.md),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AdminPalette.mutedText),
          const SizedBox(width: 7),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AdminPalette.mutedText,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(
            value.trim().isEmpty ? '-' : value,
            style: const TextStyle(
              color: AdminPalette.dark,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdeasLoadingState extends StatelessWidget {
  const _IdeasLoadingState({super.key, required this.texts});

  final _IdeasTexts texts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(texts.loading, style: const TextStyle(color: AdminPalette.bodyText, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _IdeasErrorState extends StatelessWidget {
  const _IdeasErrorState({
    super.key,
    required this.texts,
    required this.message,
    required this.onRetry,
  });

  final _IdeasTexts texts;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, size: 42, color: AdminPalette.mutedText),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AdminPalette.bodyText)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: Text(texts.tryAgain)),
        ],
      ),
    );
  }
}

class _IdeasEmptyState extends StatelessWidget {
  const _IdeasEmptyState({required this.texts, required this.hasFilter});

  final _IdeasTexts texts;
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 58),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AdminPalette.activeGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(hasFilter ? Icons.search_off_rounded : Icons.lightbulb_outline_rounded, color: AdminPalette.dark),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? texts.noResults : texts.empty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: AdminPalette.dark),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter ? texts.noResultsHint : texts.emptyHint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AdminPalette.bodyText, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _IdeasTexts {
  const _IdeasTexts({
    required this.title,
    required this.eyebrow,
    required this.subtitle,
    required this.search,
    required this.records,
    required this.ofLabel,
    required this.empty,
    required this.emptyHint,
    required this.noResults,
    required this.noResultsHint,
    required this.tryAgain,
    required this.loading,
    required this.module,
    required this.screen,
    required this.platform,
    required this.language,
    required this.company,
    required this.receivedAt,
  });

  final String title;
  final String eyebrow;
  final String subtitle;
  final String search;
  final String records;
  final String ofLabel;
  final String empty;
  final String emptyHint;
  final String noResults;
  final String noResultsHint;
  final String tryAgain;
  final String loading;
  final String module;
  final String screen;
  final String platform;
  final String language;
  final String company;
  final String receivedAt;

  factory _IdeasTexts.of(BuildContext context) {
    final String languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'en') {
      return const _IdeasTexts(
        title: 'New ideas',
        eyebrow: 'Product feedback',
        subtitle: 'Review suggestions submitted by customers through the Six AI assistant.',
        search: 'Search by idea, module, screen, company, platform or language',
        records: 'ideas',
        ofLabel: 'of',
        empty: 'No ideas received yet',
        emptyHint: 'Suggestions submitted by customers will appear here.',
        noResults: 'No ideas match this search',
        noResultsHint: 'Try changing or clearing the search term.',
        tryAgain: 'Try again',
        loading: 'Loading ideas...',
        module: 'Module',
        screen: 'Screen',
        platform: 'Platform',
        language: 'Language',
        company: 'Company',
        receivedAt: 'Received',
      );
    }
    if (languageCode == 'es') {
      return const _IdeasTexts(
        title: 'Nuevas ideas',
        eyebrow: 'Comentarios de producto',
        subtitle: 'Revisa las sugerencias enviadas por los clientes a través del asistente de IA de Six.',
        search: 'Buscar por idea, módulo, pantalla, empresa, plataforma o idioma',
        records: 'ideas',
        ofLabel: 'de',
        empty: 'Todavía no hay ideas recibidas',
        emptyHint: 'Las sugerencias enviadas por los clientes aparecerán aquí.',
        noResults: 'Ninguna idea coincide con esta búsqueda',
        noResultsHint: 'Intenta cambiar o limpiar el término de búsqueda.',
        tryAgain: 'Intentar de nuevo',
        loading: 'Cargando ideas...',
        module: 'Módulo',
        screen: 'Pantalla',
        platform: 'Plataforma',
        language: 'Idioma',
        company: 'Empresa',
        receivedAt: 'Recibida',
      );
    }
    return const _IdeasTexts(
      title: 'Novas ideias',
      eyebrow: 'Feedback de produto',
      subtitle: 'Acompanhe as sugestões enviadas pelos clientes através do assistente de IA do Six.',
      search: 'Busque por ideia, módulo, tela, empresa, plataforma ou idioma',
      records: 'ideias',
      ofLabel: 'de',
      empty: 'Nenhuma ideia recebida ainda',
      emptyHint: 'As sugestões enviadas pelos clientes aparecerão aqui.',
      noResults: 'Nenhuma ideia corresponde à busca',
      noResultsHint: 'Tente alterar ou limpar o termo pesquisado.',
      tryAgain: 'Tentar novamente',
      loading: 'Carregando ideias...',
      module: 'Módulo',
      screen: 'Tela',
      platform: 'Plataforma',
      language: 'Idioma',
      company: 'Empresa',
      receivedAt: 'Recebida',
    );
  }
}
