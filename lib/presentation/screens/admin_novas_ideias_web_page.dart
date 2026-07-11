import 'package:flutter/material.dart';

import '../../core/services/admin_ideas_service.dart';

class AdminNovasIdeiasWebPage extends StatefulWidget {
  const AdminNovasIdeiasWebPage({super.key});

  @override
  State<AdminNovasIdeiasWebPage> createState() => _AdminNovasIdeiasWebPageState();
}

class _AdminNovasIdeiasWebPageState extends State<AdminNovasIdeiasWebPage> {
  final AdminIdeasService _service = AdminIdeasService();
  final TextEditingController _filtroController = TextEditingController();

  bool _carregando = true;
  String? _erro;
  List<AdminIdeaModel> _ideias = const <AdminIdeaModel>[];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _filtroController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final ideias = await _service.listar();
      if (!mounted) return;
      setState(() {
        _ideias = ideias;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString().replaceAll('Exception: ', '');
        _carregando = false;
      });
    }
  }

  List<AdminIdeaModel> get _filtradas {
    final filtro = _filtroController.text.trim().toLowerCase();
    if (filtro.isEmpty) return _ideias;
    return _ideias.where((idea) {
      return idea.descricao.toLowerCase().contains(filtro) ||
          idea.modulo.toLowerCase().contains(filtro) ||
          idea.telaAtual.toLowerCase().contains(filtro) ||
          idea.plataforma.toLowerCase().contains(filtro) ||
          idea.idioma.toLowerCase().contains(filtro) ||
          idea.status.toLowerCase().contains(filtro);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final textos = _Texts(locale);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: Text(textos.titulo),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed('/admin/dashboard'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: <Widget>[
          IconButton(onPressed: _carregando ? null : _carregar, icon: const Icon(Icons.refresh_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _filtroController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: textos.buscar,
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Chip(label: Text('${_filtradas.length} ${textos.registros}')),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildContent(textos)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(_Texts textos) {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_erro!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _carregar, child: Text(textos.tentarNovamente)),
          ],
        ),
      );
    }
    if (_filtradas.isEmpty) return Center(child: Text(textos.vazio));

    return ListView.separated(
      itemCount: _filtradas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final idea = _filtradas[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: Text(idea.descricao, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                    const SizedBox(width: 12),
                    Chip(label: Text(idea.status)),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _info(Icons.widgets_outlined, idea.modulo),
                    _info(Icons.web_asset_outlined, idea.telaAtual),
                    _info(Icons.devices_rounded, idea.plataforma),
                    _info(Icons.language_rounded, idea.idioma),
                    _info(Icons.business_outlined, idea.empresaId),
                    _info(Icons.schedule_rounded, _formatarData(idea.criadaEm)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _info(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(value.isEmpty ? '-' : value),
      ]),
    );
  }

  String _formatarData(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(local.day)}/${dois(local.month)}/${local.year} ${dois(local.hour)}:${dois(local.minute)}';
  }
}

class _Texts {
  _Texts(String languageCode) : languageCode = languageCode.toLowerCase();
  final String languageCode;

  String get titulo => languageCode == 'en' ? 'New ideas' : languageCode == 'es' ? 'Nuevas ideas' : 'Novas ideias';
  String get buscar => languageCode == 'en' ? 'Search ideas' : languageCode == 'es' ? 'Buscar ideas' : 'Buscar ideias';
  String get registros => languageCode == 'en' ? 'records' : languageCode == 'es' ? 'registros' : 'registros';
  String get vazio => languageCode == 'en' ? 'No ideas received yet.' : languageCode == 'es' ? 'Todavía no hay ideas recibidas.' : 'Nenhuma ideia recebida ainda.';
  String get tentarNovamente => languageCode == 'en' ? 'Try again' : languageCode == 'es' ? 'Intentar de nuevo' : 'Tentar novamente';
}
