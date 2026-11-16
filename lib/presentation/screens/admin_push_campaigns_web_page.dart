import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/web_dashboard_widgets.dart';
import '../theme/web_theme_tokens.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/push_campaign_service.dart';
import '../../l10n/push_campaign_texts.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../admin/admin_navigation_shell.dart';
import '../admin/admin_portal_components.dart';
import '../admin/admin_portal_texts.dart';
import '../components/six_backend_loading.dart';
import '../layouts/six_web_page_shell.dart';

class AdminPushCampaignsWebPage extends StatefulWidget {
  const AdminPushCampaignsWebPage({
    super.key,
    this.service,
    this.embeddedInMainShell = false,
  });
  final bool embeddedInMainShell;
  final PushCampaignService? service;
  @override
  State<AdminPushCampaignsWebPage> createState() => _CampaignState();
}

class _CampaignState extends State<AdminPushCampaignsWebPage> {
  late final _service = widget.service ?? PushCampaignService();
  final _name = TextEditingController();
  final _search = TextEditingController();
  final _titles = <String, TextEditingController>{};
  final _bodies = <String, TextEditingController>{};
  final _selected = <String>{};
  List<CampaignRecipient> _audience = [];
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic>? _reviewed;
  List<CampaignRecipient> _reviewAudience = [];
  bool _loading = true, _busy = false, _editing = false;
  String? _error, _notice;
  String _language = '', _status = '', _id = const Uuid().v4();
  int _page = 0;
  int _step = 0;
  final _journeyKey = GlobalKey();
  Timer? _poll;
  String t(String key) => campaignText(context, key);
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _service.dispose();
    _name.dispose();
    _search.dispose();
    for (final c in [..._titles.values, ..._bodies.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final audience = await _service.audience();
      final history = await _service.history(_page);
      if (!mounted) return;
      setState(() {
        _audience = audience;
        _history = history;
        _loading = false;
        _error = null;
      });
      _schedulePoll();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is PushCampaignException ? e.code : 'requestError';
        });
      }
    }
  }

  void _schedulePoll() {
    _poll?.cancel();
    if (_history.any(
      (c) => ['PENDENTE', 'PROCESSANDO'].contains(c['status']),
    )) {
      _poll = Timer(const Duration(seconds: 5), () async {
        try {
          final history = await _service.history(_page);
          if (!mounted) return;
          setState(() => _history = history);
          _schedulePoll();
        } catch (_) {
          if (mounted) setState(() => _error = 'requestError');
        }
      });
    }
  }

  List<CampaignRecipient> get _filtered =>
      _audience
          .where(
            (d) =>
                (_language.isEmpty || d.language == _language) &&
                (_status.isEmpty || d.subscription == _status) &&
                '${d.name} ${d.email} ${d.company}'.toLowerCase().contains(
                  _search.text.trim().toLowerCase(),
                ),
          )
          .toList();
  List<CampaignRecipient> get _chosen =>
      _audience.where((d) => _selected.contains(d.key)).toList();
  List<String> get _languages =>
      _chosen.map((d) => d.language).toSet().toList()..sort();
  TextEditingController _title(String l) =>
      _titles.putIfAbsent(l, TextEditingController.new);
  TextEditingController _body(String l) =>
      _bodies.putIfAbsent(l, TextEditingController.new);
  Future<void> _review({bool test = false}) async {
    if (_chosen.map((d) => d.userId).toSet().length != _chosen.length) {
      setState(() => _error = 'duplicate');
      return;
    }
    if (_name.text.trim().isEmpty ||
        _chosen.isEmpty ||
        _languages.any(
          (l) => _title(l).text.trim().isEmpty || _body(l).text.trim().isEmpty,
        )) {
      setState(() => _error = 'required');
      return;
    }
    if (test && _chosen.length != 1) {
      setState(() => _error = 'testHelp');
      return;
    }
    final body = <String, dynamic>{
      'id': _id,
      'nome': _name.text.trim(),
      'teste': test,
      'destinatarios': _chosen.map((d) => d.selection).toList(),
      'mensagens': {
        for (final l in _languages)
          l: {'titulo': _title(l).text.trim(), 'texto': _body(l).text.trim()},
      },
    };
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final reviewed = await _service.review(body);
      if (mounted) {
        setState(() {
          _reviewed = body;
          _reviewAudience = reviewed;
          _step = 2;
        });
        _focusJourney();
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is PushCampaignException ? e.code : 'requestError',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final body = _reviewed;
    if (body == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.send(body);
      if (!mounted) return;
      setState(() {
        _reviewed = null;
        _editing = false;
        _notice = 'queued';
        _step = 0;
        _selected.clear();
        _name.clear();
        for (final controller in [..._titles.values, ..._bodies.values]) {
          controller.clear();
        }
        _id = const Uuid().v4();
        _page = 0;
      });
      await _load();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is PushCampaignException ? e.code : 'requestError',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: SixWebSectionCard(
      title: title,
      icon:
          title == t('history')
              ? Icons.history_rounded
              : Icons.campaign_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );

  Widget _header() => SixWebDashboardHeader(
    icon: Icons.campaign_outlined,
    title: t('title'),
    subtitle: t(_editing ? 'journeyIntro' : 'intro'),
    actions: [
      OutlinedButton.icon(
        onPressed: _busy || _loading ? null : _load,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text(t('refresh')),
      ),
      if (_editing)
        OutlinedButton.icon(
          onPressed: _busy ? null : () => setState(() => _editing = false),
          icon: const Icon(Icons.history_rounded, size: 18),
          label: Text(t('history')),
        ),
      if (!_editing)
        FilledButton.icon(
          onPressed:
              _loading
                  ? null
                  : () => setState(() {
                    _editing = true;
                    _notice = null;
                    _error = null;
                    _focusJourney();
                  }),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(
            t(_selected.isNotEmpty || _name.text.isNotEmpty ? 'resume' : 'new'),
          ),
        ),
    ],
  );

  String _historyDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '—';
    final regional = context.watch<LocaleSettingsProvider?>();
    return regional?.formatDateTime(date) ??
        DateFormat.yMd(
          Localizations.localeOf(context).toString(),
        ).add_Hm().format(date);
  }

  Widget _badge(String label, {Color? color, IconData? icon}) {
    final tokens = WebThemeTokens.of(context);
    final foreground = color ?? tokens.secondaryText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.1) ?? tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color?.withValues(alpha: 0.25) ?? tokens.cardBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        context.watch<ColaboradorAutorizacoesProvider>().tipoPerfilUnificado;
    final Widget content =
        profile != 'SUPER'
            ? Center(child: Text(t('access')))
            : _loading
            ? const SixBackendLoading.messages()
            : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: 20),
                if (_error != null)
                  _section(t('title'), [
                    Text(
                      t(_error!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ]),
                if (_notice != null) _section(t('title'), [Text(t(_notice!))]),
                if (_editing) ...[
                  _journeyProgress(),
                  const SizedBox(height: 20),
                  if (_step < 2) ..._editor(),
                  if (_step == 2 && _reviewed != null) ..._confirmation(),
                ] else
                  ..._historyView(),
              ],
            );
    if (widget.embeddedInMainShell) {
      return SixWebPageShell(
        child: SingleChildScrollView(
          padding: SixWebPageShell.scrollPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [content],
          ),
        ),
      );
    }
    return AdminNavigationShell(
      texts: AdminPortalTexts.of(context),
      userInfo: AdminPortalUserInfo(profileType: profile),
      currentRoute: '/admin/campanhas-push',
      pageTitle: t('title'),
      onLogout: () async {
        await AuthService().logout();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/admin', (_) => false);
        }
      },
      onRefresh: _busy ? () {} : _load,
      refreshing: _loading,
      loggingOut: false,
      child: content,
    );
  }

  void _focusJourney() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_editing) return;
      final target = _journeyKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(target, alignment: 0);
      }
    });
  }

  void _continueToMessage() {
    if (_chosen.isEmpty) {
      setState(() => _error = 'audienceRequired');
      return;
    }
    if (_chosen.map((d) => d.userId).toSet().length != _chosen.length) {
      setState(() => _error = 'duplicate');
      return;
    }
    setState(() {
      _step = 1;
      _error = null;
    });
    _focusJourney();
  }

  Widget _journeyProgress() {
    final tokens = WebThemeTokens.of(context);
    final labels = [t('audience'), t('body'), t('reviewStage')];
    final hints = [t('audienceStep'), t('messageStep'), t('reviewStep')];
    return Container(
      key: _journeyKey,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              for (var index = 0; index < labels.length; index++)
                Semantics(
                  selected: index == _step,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          index == _step
                              ? tokens.selectedBackground
                              : tokens.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            index == _step
                                ? tokens.selectedBorder
                                : tokens.cardBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (index < _step)
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                            color: tokens.success,
                          )
                        else
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color:
                                  index == _step
                                      ? tokens.primaryText
                                      : tokens.mutedText,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              fontWeight:
                                  index == _step
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                              color:
                                  index == _step
                                      ? tokens.primaryText
                                      : tokens.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            hints[_step],
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.secondaryText),
          ),
        ],
      ),
    );
  }

  List<Widget> _editor() => [
    if (_step == 0)
      _section(t('audience'), [
        Text(t('companyRule')),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          decoration: InputDecoration(
            labelText: t('search'),
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            DropdownButton<String>(
              value: _language,
              items: [
                DropdownMenuItem(value: '', child: Text(t('allLanguages'))),
                ...(_audience.map((d) => d.language).toSet().toList()..sort())
                    .map(
                      (l) => DropdownMenuItem(
                        value: l,
                        child: Text(l.toUpperCase()),
                      ),
                    ),
              ],
              onChanged: (v) => setState(() => _language = v!),
            ),
            DropdownButton<String>(
              value: _status,
              items: [
                DropdownMenuItem(value: '', child: Text(t('allStatuses'))),
                ..._audience
                    .map((d) => d.subscription)
                    .toSet()
                    .map((s) => DropdownMenuItem(value: s, child: Text(t(s)))),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            TextButton(
              onPressed:
                  () => setState(
                    () => _selected.addAll(_filtered.map((d) => d.key)),
                  ),
              child: Text(t('all')),
            ),
            TextButton(
              onPressed: () => setState(_selected.clear),
              child: Text(t('clear')),
            ),
          ],
        ),
        Text('${t('selected')}: ${_chosen.length}'),
        const SizedBox(height: 8),
        SizedBox(
          height: 280,
          child:
              _filtered.isEmpty
                  ? Center(child: Text(t('empty')))
                  : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final d = _filtered[i];
                      return CheckboxListTile(
                        value: _selected.contains(d.key),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          '${d.name} · ${d.company}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${d.email} · ${d.language.toUpperCase()} · ${t(d.subscription)} · ${d.devices == 0 ? t('noDevice') : '${t('devices')}: ${d.devices}'}',
                        ),
                        onChanged:
                            (v) => setState(() {
                              if (v == true) {
                                _selected.add(d.key);
                              } else {
                                _selected.remove(d.key);
                              }
                            }),
                      );
                    },
                  ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _busy ? null : _continueToMessage,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(t('continueMessage')),
          ),
        ),
      ]),
    if (_step == 1)
      _section(t('body'), [
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: TextField(
              controller: _name,
              maxLength: 100,
              decoration: _messageInput(t('name')),
            ),
          ),
        ),
        for (final language in _languages) _languageEditor(language),
        const SizedBox(height: 16),
        Text(t('destination')),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            TextButton.icon(
              onPressed:
                  _busy
                      ? null
                      : () => setState(() {
                        _step = 0;
                        _error = null;
                        _focusJourney();
                      }),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(t('backAudience')),
            ),
            FilledButton(
              onPressed: _busy ? null : _review,
              child: Text(t('review')),
            ),
            OutlinedButton(
              onPressed:
                  _busy || _chosen.length != 1
                      ? null
                      : () => _review(test: true),
              child: Text(t('test')),
            ),
          ],
        ),
        Text(t('testHelp')),
        if (_busy) const SixBackendLoading.messages(compact: true),
      ]),
  ];
  InputDecoration _messageInput(String label) {
    final tokens = WebThemeTokens.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: tokens.cardBorder),
    );
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: tokens.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _languageEditor(String language) {
    final tokens = WebThemeTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final title = _title(language).text;
    final body = _body(language).text;
    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _title(language),
          maxLength: 80,
          decoration: _messageInput(t('messageTitle')),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _body(language),
          maxLength: 500,
          minLines: 4,
          maxLines: 8,
          decoration: _messageInput(t('body')),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
    final preview = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('preview'),
            style: textTheme.labelLarge?.copyWith(color: tokens.secondaryText),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 18,
                      color: tokens.mutedText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SIXO',
                      style: textTheme.labelSmall?.copyWith(
                        color: tokens.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title.isEmpty ? t('previewTitle') : title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color:
                        title.isEmpty ? tokens.mutedText : tokens.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body.isEmpty ? t('previewBody') : body,
                  style: textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color:
                        body.isEmpty ? tokens.mutedText : tokens.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _badge(t('language_$language'), icon: Icons.translate_rounded),
              Text(
                '${t('audience')}: ${_chosen.where((d) => d.language == language).length}',
                style: textTheme.bodySmall?.copyWith(
                  color: tokens.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 800) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [fields, const SizedBox(height: 16), preview],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: fields),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: preview),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _reviewMessage(String language) {
    final tokens = WebThemeTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final message = (_reviewed!['mensagens'] as Map)[language];
    final recipients = _reviewAudience.where((d) => d.language == language);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _badge(
              t('language_$language'),
              icon: Icons.translate_rounded,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('messageTitle'),
                  style: textTheme.labelSmall?.copyWith(
                    color: tokens.mutedText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${message['titulo']}',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.primaryText,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t('body'),
                  style: textTheme.labelSmall?.copyWith(
                    color: tokens.mutedText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${message['texto']}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: tokens.secondaryText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t('audience'),
            style: textTheme.labelLarge?.copyWith(color: tokens.secondaryText),
          ),
          const SizedBox(height: 8),
          for (final recipient in recipients)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: tokens.mutedText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipient.name,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recipient.company,
                          style: textTheme.bodySmall?.copyWith(
                            color: tokens.mutedText,
                          ),
                        ),
                        if (recipient.devices == 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            t('noDevice'),
                            style: textTheme.bodySmall?.copyWith(
                              color: tokens.warning,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _confirmation() => [
    _section(t('review'), [
      Text(
        '${_reviewed!['nome']}',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _badge(
            '${t('selected')}: ${_reviewAudience.length}',
            icon: Icons.people_outline_rounded,
          ),
          _badge(
            '${t('noDevice')}: ${_reviewAudience.where((d) => d.devices == 0).length}',
            icon: Icons.phonelink_off_rounded,
            color:
                _reviewAudience.any((d) => d.devices == 0)
                    ? WebThemeTokens.of(context).warning
                    : null,
          ),
          if (_reviewed!['teste'] == true)
            _badge(t('testLabel'), icon: Icons.science_outlined),
        ],
      ),
      const SizedBox(height: 24),
      LayoutBuilder(
        builder: (context, constraints) {
          final languages =
              _reviewAudience.map((d) => d.language).toSet().toList()..sort();
          final width =
              constraints.maxWidth >= 820
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final language in languages)
                SizedBox(width: width, child: _reviewMessage(language)),
            ],
          );
        },
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: WebThemeTokens.of(context).surfaceMuted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: WebThemeTokens.of(context).cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: WebThemeTokens.of(context).mutedText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('destination'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t('acceptedNote'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: WebThemeTokens.of(context).secondaryText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : _send,
            icon: const Icon(Icons.send),
            label: Text(t('send')),
          ),
          TextButton(
            onPressed:
                _busy
                    ? null
                    : () => setState(() {
                      _reviewed = null;
                      _step = 1;
                      _error = null;
                      _focusJourney();
                      _id = const Uuid().v4();
                    }),
            child: Text(t('back')),
          ),
        ],
      ),
      if (_busy) const SixBackendLoading.messages(compact: true),
    ]),
  ];
  Widget _historyDetails(Map<String, dynamic> campaign) {
    final tokens = WebThemeTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final messages = campaign['mensagens'] as Map;
    final recipients = campaign['destinatarios'] as List;
    final results = campaign['resultados'] as List;

    Widget heading(String label, IconData icon) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: tokens.mutedText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: tokens.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    final messagePanel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading(t('body'), Icons.chat_bubble_outline_rounded),
        for (final entry in messages.entries)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _badge(
                  t('language_${entry.key}'),
                  icon: Icons.translate_rounded,
                ),
                const SizedBox(height: 12),
                Text(
                  '${entry.value['titulo']}',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${entry.value['texto']}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: tokens.secondaryText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    final audiencePanel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading(t('audience'), Icons.people_outline_rounded),
        for (final recipient in recipients)
          Builder(
            builder: (context) {
              final matches = results.where(
                (r) => r['usuarioId'] == recipient['usuarioId'],
              );
              final result = matches.isEmpty ? null : matches.first;
              final status = result?['status'] ?? campaign['status'];
              final color =
                  status == 'ACEITO'
                      ? tokens.success
                      : status == 'FALHA' || status == 'INTERROMPIDA'
                      ? tokens.danger
                      : tokens.secondaryText;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: tokens.cardBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${recipient['nome']}',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: tokens.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${recipient['empresa']} · ${t('language_${recipient['idioma']}')}',
                      style: textTheme.bodySmall?.copyWith(
                        color: tokens.mutedText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _badge(t(status as String), color: color),
                        if (result != null) ...[
                          _badge(
                            '${t('acceptedCount')}: ${result['aceitos']}',
                            icon: Icons.check_rounded,
                          ),
                          _badge(
                            '${t('failedCount')}: ${result['falhas']}',
                            color:
                                (result['falhas'] as num? ?? 0) > 0
                                    ? tokens.danger
                                    : null,
                            icon: Icons.error_outline_rounded,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 24, color: tokens.divider),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  messagePanel,
                  const SizedBox(height: 16),
                  audiencePanel,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: messagePanel),
                const SizedBox(width: 24),
                Expanded(child: audiencePanel),
              ],
            );
          },
        ),
        if (campaign['autor'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${t('authorId')}: ${campaign['autor']}',
              style: textTheme.bodySmall?.copyWith(color: tokens.mutedText),
            ),
          ),
      ],
    );
  }

  List<Widget> _historyView() => [
    _section(t('history'), [
      Text(t('acceptedNote')),
      const SizedBox(height: 12),
      if (_history.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 32,
                color: WebThemeTokens.of(context).mutedText,
              ),
              const SizedBox(height: 12),
              Text(t('empty')),
            ],
          ),
        ),
      for (final c in _history)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: WebThemeTokens.of(context).surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WebThemeTokens.of(context).cardBorder),
            ),
            child: ExpansionTile(
              key: PageStorageKey(c['id'] ?? c['criadoEm']),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                '${c['nome']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _badge(
                      t(c['status'] as String),
                      color:
                          c['status'] == 'CONCLUIDA'
                              ? WebThemeTokens.of(context).success
                              : c['status'] == 'INTERROMPIDA'
                              ? WebThemeTokens.of(context).warning
                              : WebThemeTokens.of(context).info,
                      icon:
                          c['status'] == 'CONCLUIDA'
                              ? Icons.check_circle_outline
                              : Icons.schedule_outlined,
                    ),
                    _badge(
                      _historyDate(c['criadoEm']),
                      icon: Icons.calendar_today_outlined,
                    ),
                    if (c['teste'] == true)
                      _badge(t('testLabel'), icon: Icons.science_outlined),
                  ],
                ),
              ),
              children: [_historyDetails(c)],
            ),
          ),
        ),
      const Divider(height: 28),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          TextButton(
            onPressed:
                _page == 0
                    ? null
                    : () {
                      setState(() => _page--);
                      _load();
                    },
            child: Text(t('previous')),
          ),
          TextButton(
            onPressed:
                _history.length < 20
                    ? null
                    : () {
                      setState(() => _page++);
                      _load();
                    },
            child: Text(t('next')),
          ),
          TextButton(onPressed: _load, child: Text(t('refresh'))),
        ],
      ),
    ]),
  ];
}
