import 'dart:convert';

import 'package:flutter/material.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';

class AtendimentoTecnicoAssinaturaPublicaPage extends StatefulWidget {
  const AtendimentoTecnicoAssinaturaPublicaPage({super.key, required this.initialUri});

  final Uri initialUri;

  @override
  State<AtendimentoTecnicoAssinaturaPublicaPage> createState() => _AtendimentoTecnicoAssinaturaPublicaPageState();
}

class _AtendimentoTecnicoAssinaturaPublicaPageState extends State<AtendimentoTecnicoAssinaturaPublicaPage> {
  final AtendimentoTecnicoService _service = AtendimentoTecnicoService();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();
  final List<Offset?> _pontosAssinatura = <Offset?>[];

  late final String _token;
  late final String _idUnicoDaEmpresa;
  late Future<_AssinaturaPublicaState> _future;
  bool _aceitou = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _token = widget.initialUri.queryParameters['token'] ?? '';
    _idUnicoDaEmpresa = widget.initialUri.queryParameters['idUnicoDaEmpresa'] ?? '';
    _future = _carregar();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _documentoController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<_AssinaturaPublicaState> _carregar() async {
    if (_token.isEmpty || _idUnicoDaEmpresa.isEmpty) {
      throw Exception('Link inválido. Token ou comércio não informado.');
    }
    final response = await _service.consultarAssinaturaPublica(idUnicoDaEmpresa: _idUnicoDaEmpresa, token: _token);
    final atendimentoJson = response['atendimento'];
    if (atendimentoJson is! Map<String, dynamic>) {
      throw Exception('Atendimento não encontrado para este link.');
    }
    return _AssinaturaPublicaState(
      utilizado: response['utilizado'] == true,
      atendimento: AtendimentoTecnicoModel.fromJson(atendimentoJson),
    );
  }

  Future<void> _aprovar() async {
    if (_salvando) return;
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      _mostrarMensagem('Informe o nome de quem está assinando.');
      return;
    }
    if (!_aceitou) {
      _mostrarMensagem('Confirme que aprova os produtos, serviços e valores.');
      return;
    }
    if (_pontosAssinatura.whereType<Offset>().length < 4) {
      _mostrarMensagem('Faça a assinatura no campo indicado.');
      return;
    }

    setState(() => _salvando = true);
    try {
      await _service.aprovarAssinaturaPublica(
        idUnicoDaEmpresa: _idUnicoDaEmpresa,
        token: _token,
        nomeAssinante: nome,
        documentoAssinante: _documentoController.text.trim().isEmpty ? null : _documentoController.text.trim(),
        assinaturaDataUrl: _assinaturaSerializada(),
        observacao: _observacaoController.text.trim().isEmpty ? null : _observacaoController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _future = _carregar());
      _mostrarMensagem('Serviço aprovado e assinatura salva.');
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível aprovar: $error');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  String _assinaturaSerializada() {
    final pontos = _pontosAssinatura.map((ponto) {
      if (ponto == null) return null;
      return <String, double>{'x': ponto.dx, 'y': ponto.dy};
    }).toList(growable: false);
    return jsonEncode(<String, dynamic>{'tipo': 'flutter-points-signature', 'pontos': pontos});
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating));
  }

  String _formatarMoeda(double value) => 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: FutureBuilder<_AssinaturaPublicaState>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _ErroPublico(mensagem: snapshot.error.toString(), onRetry: () => setState(() => _future = _carregar()));
          final state = snapshot.data!;
          final atendimento = state.atendimento;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  _card(
                    theme,
                    Row(
                      children: <Widget>[
                        Icon(Icons.draw_outlined, color: theme.colorScheme.primary, size: 42),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Aprovação de serviço', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text(state.utilizado ? 'Este link já foi utilizado.' : 'Confira o atendimento e assine para aprovar.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildResumo(theme, atendimento),
                  const SizedBox(height: 14),
                  _buildItens(theme, atendimento),
                  const SizedBox(height: 14),
                  state.utilizado ? _buildJaUtilizado(theme) : _buildAssinatura(theme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumo(ThemeData theme, AtendimentoTecnicoModel atendimento) {
    final equipamento = atendimento.equipamento;
    final equipamentoTexto = <String>[equipamento?.tipo ?? '', equipamento?.marca ?? '', equipamento?.modelo ?? '']
        .where((item) => item.trim().isNotEmpty)
        .join(' ');
    return _card(
      theme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Dados do atendimento', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _linha('Número', atendimento.numero),
          _linha('Cliente', atendimento.nomeClienteSnapshot ?? 'Cliente não informado'),
          _linha('Status', atendimento.statusNomePtBr ?? atendimento.statusCodigo),
          _linha('Equipamento', equipamentoTexto.isEmpty ? 'Não informado' : equipamentoTexto),
          if ((equipamento?.imei ?? '').trim().isNotEmpty) _linha('IMEI', equipamento!.imei!),
          if ((atendimento.defeitoRelatado ?? '').trim().isNotEmpty) _linha('Defeito', atendimento.defeitoRelatado!),
          if ((atendimento.diagnosticoTecnico ?? '').trim().isNotEmpty) _linha('Diagnóstico', atendimento.diagnosticoTecnico!),
          const Divider(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _total(theme, 'Produtos', atendimento.valorTotalProdutos),
              _total(theme, 'Serviços', atendimento.valorTotalServicos),
              _total(theme, 'Total', atendimento.valorTotalAtendimento),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItens(ThemeData theme, AtendimentoTecnicoModel atendimento) {
    return _card(
      theme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Produtos e serviços', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          if (atendimento.itens.isEmpty)
            Text('Nenhum item informado.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
          else
            ...atendimento.itens.map((item) => _item(theme, item)),
        ],
      ),
    );
  }

  Widget _buildAssinatura(ThemeData theme) {
    return _card(
      theme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Assinatura', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          TextField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome do assinante')),
          const SizedBox(height: 12),
          TextField(controller: _documentoController, decoration: const InputDecoration(labelText: 'Documento do assinante')),
          const SizedBox(height: 12),
          TextField(controller: _observacaoController, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Observação opcional')),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(child: Text('Assine no campo abaixo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
              TextButton.icon(onPressed: () => setState(_pontosAssinatura.clear), icon: const Icon(Icons.cleaning_services_outlined), label: const Text('Limpar')),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 220,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: theme.colorScheme.outlineVariant)),
            child: GestureDetector(
              onPanStart: (details) => setState(() => _pontosAssinatura.add(details.localPosition)),
              onPanUpdate: (details) => setState(() => _pontosAssinatura.add(details.localPosition)),
              onPanEnd: (_) => setState(() => _pontosAssinatura.add(null)),
              child: CustomPaint(painter: _AssinaturaPainter(_pontosAssinatura), child: const SizedBox.expand()),
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _aceitou,
            onChanged: (value) => setState(() => _aceitou = value == true),
            title: const Text('Aprovo os produtos, serviços, valores e condições apresentados neste atendimento.'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _salvando ? null : _aprovar,
              icon: _salvando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle_outline),
              label: Text(_salvando ? 'Enviando...' : 'Aprovar e assinar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJaUtilizado(ThemeData theme) {
    return _card(
      theme,
      Row(
        children: <Widget>[
          Icon(Icons.verified_outlined, color: theme.colorScheme.primary, size: 36),
          const SizedBox(width: 12),
          const Expanded(child: Text('Este atendimento já foi aprovado por assinatura. Solicite um novo link à loja se precisar revisar.')),
        ],
      ),
    );
  }

  Widget _card(ThemeData theme, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.colorScheme.outlineVariant)),
      child: child,
    );
  }

  Widget _linha(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))), Expanded(child: Text(value))]),
    );
  }

  Widget _total(ThemeData theme, String label, double value) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.48), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)), const SizedBox(height: 4), Text(_formatarMoeda(value), style: const TextStyle(fontWeight: FontWeight.w900))]),
    );
  }

  Widget _item(ThemeData theme, AtendimentoTecnicoItemModel item) {
    final servico = item.tipoItemCodigo == 'SERVICE';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(16)),
      child: Row(children: <Widget>[
        Icon(servico ? Icons.handyman_outlined : Icons.inventory_2_outlined, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(item.descricaoSnapshot, style: const TextStyle(fontWeight: FontWeight.w900))),
        Text('${item.quantidade.toStringAsFixed(0)} x ${_formatarMoeda(item.valorUnitario)}'),
        const SizedBox(width: 12),
        SizedBox(width: 100, child: Text(_formatarMoeda(item.valorTotal), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900))),
      ]),
    );
  }
}

class _AssinaturaPublicaState {
  const _AssinaturaPublicaState({required this.utilizado, required this.atendimento});
  final bool utilizado;
  final AtendimentoTecnicoModel atendimento;
}

class _ErroPublico extends StatelessWidget {
  const _ErroPublico({required this.mensagem, required this.onRetry});
  final String mensagem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(26), border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.30))),
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Icon(Icons.link_off_rounded, color: theme.colorScheme.error, size: 46),
          const SizedBox(height: 12),
          Text('Não foi possível abrir o link', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(mensagem, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Tentar novamente')),
        ]),
      ),
    );
  }
}

class _AssinaturaPainter extends CustomPainter {
  const _AssinaturaPainter(this.points);
  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      if (current != null && next != null) canvas.drawLine(current, next, paint);
    }
    final guide = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;
    canvas.drawLine(Offset(18, size.height - 32), Offset(size.width - 18, size.height - 32), guide);
  }

  @override
  bool shouldRepaint(covariant _AssinaturaPainter oldDelegate) => true;
}
