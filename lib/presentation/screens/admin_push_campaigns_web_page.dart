import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/push_campaign_service.dart';
import '../../l10n/push_campaign_texts.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../admin/admin_navigation_shell.dart';
import '../admin/admin_portal_components.dart';
import '../admin/admin_portal_texts.dart';
import '../components/six_backend_loading.dart';

class AdminPushCampaignsWebPage extends StatefulWidget {
  const AdminPushCampaignsWebPage({super.key, this.service});
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
        });
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

  Widget _section(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final profile =
        context.watch<ColaboradorAutorizacoesProvider>().tipoPerfilUnificado;
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
      child:
          profile != 'SUPER'
              ? Center(child: Text(t('access')))
              : _loading
              ? const SixBackendLoading.messages()
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t('intro')),
                  const SizedBox(height: 16),
                  if (_error != null)
                    _section(t('title'), [
                      Text(
                        t(_error!),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ]),
                  if (_notice != null)
                    _section(t('title'), [Text(t(_notice!))]),
                  if (!_editing)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed:
                            () => setState(() {
                              _editing = true;
                              _notice = null;
                              _error = null;
                              _reviewed = null;
                            }),
                        icon: const Icon(Icons.campaign_outlined),
                        label: Text(t('new')),
                      ),
                    ),
                  if (_editing && _reviewed == null) ..._editor(),
                  if (_reviewed != null) ..._confirmation(),
                  const SizedBox(height: 20),
                  ..._historyView(),
                ],
              ),
    );
  }

  List<Widget> _editor() => [
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
    ]),
    _section(t('body'), [
      TextField(
        controller: _name,
        maxLength: 100,
        decoration: InputDecoration(labelText: t('name')),
      ),
      for (final l in _languages) ...[
        const SizedBox(height: 18),
        Text(
          '${l.toUpperCase()} · ${_chosen.where((d) => d.language == l).length} ADMINs',
        ),
        TextField(
          controller: _title(l),
          maxLength: 80,
          decoration: InputDecoration(labelText: t('messageTitle')),
          onChanged: (_) => setState(() {}),
        ),
        TextField(
          controller: _body(l),
          maxLength: 500,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: t('body')),
          onChanged: (_) => setState(() {}),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SIXO · ${t('preview')}'),
              const SizedBox(height: 8),
              Text(
                _title(l).text,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_body(l).text),
            ],
          ),
        ),
      ],
      const SizedBox(height: 16),
      Text(t('destination')),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton(
            onPressed: _busy ? null : _review,
            child: Text(t('review')),
          ),
          OutlinedButton(
            onPressed:
                _busy || _chosen.length != 1 ? null : () => _review(test: true),
            child: Text(t('test')),
          ),
        ],
      ),
      Text(t('testHelp')),
    ]),
  ];
  List<Widget> _confirmation() => [
    _section(t('review'), [
      Text(
        '${_reviewed!['nome']}${_reviewed!['teste'] == true ? ' · ${t('testLabel')}' : ''}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Text(
        '${t('selected')}: ${_reviewAudience.length} · ${t('noDevice')}: ${_reviewAudience.where((d) => d.devices == 0).length}',
      ),
      for (final l in _reviewAudience.map((d) => d.language).toSet())
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '$l: ${(_reviewed!['mensagens'] as Map)[l]['titulo']}\n${(_reviewed!['mensagens'] as Map)[l]['texto']}',
          ),
        ),
      Text(_reviewAudience.map((d) => '${d.name} (${d.company})').join(', ')),
      const SizedBox(height: 12),
      Text(t('destination')),
      Text(t('acceptedNote')),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
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
                      _id = const Uuid().v4();
                    }),
            child: Text(t('back')),
          ),
        ],
      ),
      if (_busy) const SixBackendLoading.messages(compact: true),
    ]),
  ];
  List<Widget> _historyView() => [
    _section(t('history'), [
      Text(t('acceptedNote')),
      const SizedBox(height: 12),
      if (_history.isEmpty) Text(t('empty')),
      for (final c in _history)
        ExpansionTile(
          title: Text('${c['nome']} · ${t(c['status'] as String)}'),
          subtitle: Text(
            '${c['criadoEm']} · ${c['autor']}${c['teste'] == true ? ' · ${t('testLabel')}' : ''}',
          ),
          children: [
            for (final e in (c['mensagens'] as Map).entries)
              ListTile(
                title: Text('${e.key}: ${e.value['titulo']}'),
                subtitle: Text('${e.value['texto']}'),
              ),
            for (final d in (c['destinatarios'] as List))
              Builder(
                builder: (context) {
                  final results = (c['resultados'] as List).where(
                    (r) => r['usuarioId'] == d['usuarioId'],
                  );
                  final r = results.isEmpty ? null : results.first;
                  return ListTile(
                    title: Text(
                      '${d['nome']} · ${d['empresa']} · ${d['idioma']}',
                    ),
                    subtitle: Text(
                      r == null
                          ? t(c['status'] as String)
                          : '${t(r['status'] as String)} · ${t('ACEITO')}: ${r['aceitos']} · ${t('FALHA')}: ${r['falhas']}',
                    ),
                  );
                },
              ),
          ],
        ),
      Wrap(
        spacing: 12,
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
