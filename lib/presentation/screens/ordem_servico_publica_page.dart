import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class OrdemServicoPublicaPage extends StatefulWidget {
  const OrdemServicoPublicaPage({
    super.key,
    required this.ordemId,
    required this.initialUri,
  });

  final String ordemId;
  final Uri initialUri;

  @override
  State<OrdemServicoPublicaPage> createState() => _OrdemServicoPublicaPageState();
}

class _OrdemServicoPublicaPageState extends State<OrdemServicoPublicaPage> {
  late final SignatureController _signatureController;
  bool _aceitouTermos = false;
  bool _assinaturaConcluida = false;
  DateTime? _assinadoEm;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 2.6,
      penColor: const Color(0xFF1F3C88),
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  String _query(String key, {String fallback = '-'}) {
    final String? value = widget.initialUri.queryParameters[key];
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }
    return value;
  }

  String _numeroOs() => _query('numeroOs', fallback: widget.ordemId);
  String _cliente() => _query('cliente');
  String _equipamento() => _query('equipamento');
  String _status() => _query('status');
  String _tecnico() => _query('tecnico');
  String _prazo() => _query('prazo');
  String _garantia() => _query('garantia');
  String _tipoAtendimento() => _query('tipoAtendimento');
  String _defeito() => _query('defeito');
  String _itens() => _query('itens', fallback: '0');
  String _total() => _query('total', fallback: '0.00');

  Future<void> _confirmarAssinatura() async {
    if (!_aceitouTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Confirme a autorização para concluir a assinatura.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faça a assinatura na área indicada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _assinaturaConcluida = true;
      _assinadoEm = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Assinatura registrada com sucesso nesta sessão pública.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildHighlightCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoCard() {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo da ordem de serviço',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Esta é uma visualização pública, sem login, criada para o cliente conferir as informações e assinar digitalmente.',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              SizedBox(
                width: 260,
                child: _buildHighlightCard(
                  icon: Icons.confirmation_number_outlined,
                  title: 'Número da OS',
                  value: _numeroOs(),
                ),
              ),
              SizedBox(
                width: 260,
                child: _buildHighlightCard(
                  icon: Icons.person_outline,
                  title: 'Cliente',
                  value: _cliente(),
                ),
              ),
              SizedBox(
                width: 260,
                child: _buildHighlightCard(
                  icon: Icons.devices_other_outlined,
                  title: 'Equipamento',
                  value: _equipamento(),
                ),
              ),
              SizedBox(
                width: 260,
                child: _buildHighlightCard(
                  icon: Icons.flag_outlined,
                  title: 'Status',
                  value: _status(),
                ),
              ),
              SizedBox(
                width: 260,
                child: _buildHighlightCard(
                  icon: Icons.engineering_outlined,
                  title: 'Técnico',
                  value: _tecnico(),
                ),
              ),
              SizedBox(
                width: 260,
                child: _buildHighlightCard(
                  icon: Icons.schedule_outlined,
                  title: 'Prazo',
                  value: _prazo(),
                ),
              ),
              SizedBox(
                width: 260,
                child: _buildHighlightCard(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Itens aprovados',
                  value: _itens(),
                ),
              ),
              SizedBox(
                width: 260,
                child: _buildHighlightCard(
                  icon: Icons.payments_outlined,
                  title: 'Total previsto',
                  value: 'R\$ ${_total()}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalhes informados ao cliente',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text('Tipo de atendimento: ${_tipoAtendimento()}'),
                const SizedBox(height: 8),
                Text('Garantia: ${_garantia()}'),
                const SizedBox(height: 8),
                Text('Defeito relatado: ${_defeito()}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssinaturaCard() {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assinatura digital do cliente',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Assine no quadro abaixo para confirmar ciência do resumo apresentado. Nesta fase, a assinatura é local e funciona sem backend.',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          CheckboxListTile(
            value: _aceitouTermos,
            onChanged: _assinaturaConcluida
                ? null
                : (value) {
                    setState(() {
                      _aceitouTermos = value ?? false;
                    });
                  },
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Confirmo que li o resumo e autorizo o registro desta assinatura digital.',
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(22),
              ),
              child: SizedBox(
                height: 240,
                width: double.infinity,
                child: IgnorePointer(
                  ignoring: _assinaturaConcluida,
                  child: Signature(
                    controller: _signatureController,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _assinaturaConcluida
                    ? null
                    : () {
                        _signatureController.clear();
                        setState(() {});
                      },
                icon: const Icon(Icons.layers_clear_outlined),
                label: const Text('Limpar assinatura'),
              ),
              FilledButton.icon(
                onPressed: _assinaturaConcluida ? null : _confirmarAssinatura,
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Concluir assinatura'),
              ),
            ],
          ),
          if (_assinaturaConcluida && _assinadoEm != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.green.withOpacity(0.30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assinatura concluída',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Registro local efetuado em ${_assinadoEm!.toLocal()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Resumo público da ordem de serviço'),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.10),
                        theme.colorScheme.surface,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Wrap(
                    spacing: 18,
                    runSpacing: 14,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(
                          Icons.assignment_turned_in_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ordem ${_numeroOs()}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Acesso público liberado para conferência e assinatura digital.',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.public_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Sem login',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _buildResumoCard(),
                const SizedBox(height: 22),
                _buildAssinaturaCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
