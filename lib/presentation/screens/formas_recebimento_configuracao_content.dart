import 'package:flutter/material.dart';

import '../../data/models/caixa_models.dart';
import '../../data/services/caixa/caixa_api_client.dart';
import '../../domain/services/caixa/caixa_service.dart';
import '../components/six_backend_loading.dart';
import '../components/web_dashboard_widgets.dart';

class FormasRecebimentoConfiguracaoContent extends StatefulWidget {
  const FormasRecebimentoConfiguracaoContent({super.key});

  @override
  State<FormasRecebimentoConfiguracaoContent> createState() =>
      _FormasRecebimentoConfiguracaoContentState();
}

class _FormasRecebimentoConfiguracaoContentState
    extends State<FormasRecebimentoConfiguracaoContent> {
  late final CaixaService _caixaService;

  List<TiposRecebimento> _tipos = const <TiposRecebimento>[];
  bool _carregando = true;
  bool _restaurandoPadrao = false;
  String? _erro;
  String? _salvandoCodigo;

  @override
  void initState() {
    super.initState();
    _caixaService = CaixaService(apiClient: HttpCaixaApiClient());
    _carregarTipos();
  }

  List<TiposRecebimento> get _tiposOrdenados {
    final List<TiposRecebimento> ordenados = List<TiposRecebimento>.of(_tipos);
    ordenados.sort((TiposRecebimento a, TiposRecebimento b) {
      final int ordem = a.ordemExibicao.compareTo(b.ordemExibicao);
      if (ordem != 0) return ordem;
      return _numeroTipo(a.codigoTipo).compareTo(_numeroTipo(b.codigoTipo));
    });
    return ordenados;
  }

  Future<void> _carregarTipos({bool manterConteudoAtual = false}) async {
    setState(() {
      _carregando = true;
      if (!manterConteudoAtual) _erro = null;
    });

    try {
      final List<TiposRecebimento> tipos = await _caixaService.listarTiposRecebimentoConfiguraveis();
      if (!mounted) return;
      setState(() {
        _tipos = tipos;
        _carregando = false;
        _erro = null;
      });
    } on CaixaApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = _mensagemErro(error.statusCode);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Não foi possível carregar as formas de recebimento.';
      });
    }
  }

  String _mensagemErro(int statusCode, {bool alteracao = false}) {
    switch (statusCode) {
      case 400:
        return 'Dados inválidos para esta operação.';
      case 401:
        return 'Sessão expirada. Faça login novamente.';
      case 403:
        return 'Você não possui permissão para alterar configurações da empresa.';
      case 404:
        return 'Configuração de forma de recebimento não encontrada.';
      default:
        return alteracao
            ? 'Erro ao salvar forma de recebimento (HTTP $statusCode).'
            : 'Erro ao carregar formas de recebimento (HTTP $statusCode).';
    }
  }

  Future<void> _editarTipo(TiposRecebimento tipo) async {
    final TiposRecebimento? atualizado = await showDialog<TiposRecebimento>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => _TipoRecebimentoEditDialog(tipo: tipo),
    );

    if (atualizado == null) return;

    setState(() => _salvandoCodigo = tipo.codigoTipo);
    try {
      await _caixaService.atualizarTipoRecebimentoConfiguravel(
        codigoTipo: tipo.codigoTipo,
        tipo: atualizado,
      );
      if (!mounted) return;
      await _carregarTipos(manterConteudoAtual: true);
      if (!mounted) return;
      _mostrarMensagem('Forma de recebimento atualizada com sucesso.');
    } on CaixaApiException catch (error) {
      if (!mounted) return;
      _mostrarMensagem(_mensagemErro(error.statusCode, alteracao: true), erro: true);
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível salvar a forma de recebimento.', erro: true);
    } finally {
      if (mounted) setState(() => _salvandoCodigo = null);
    }
  }

  Future<void> _restaurarPadrao() async {
    final bool confirmar = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext dialogContext) => AlertDialog(
            icon: const Icon(Icons.restart_alt_rounded),
            title: const Text('Restaurar padrão'),
            content: const Text(
              'Esta ação restaura os tipos de recebimento para a configuração padrão da empresa.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Restaurar padrão'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmar) return;

    setState(() => _restaurandoPadrao = true);
    try {
      await _caixaService.restaurarTiposRecebimentoPadrao();
      if (!mounted) return;
      await _carregarTipos(manterConteudoAtual: true);
      if (!mounted) return;
      _mostrarMensagem('Configuração padrão restaurada com sucesso.');
    } on CaixaApiException catch (error) {
      if (!mounted) return;
      _mostrarMensagem(_mensagemErro(error.statusCode, alteracao: true), erro: true);
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível restaurar a configuração padrão.', erro: true);
    } finally {
      if (mounted) setState(() => _restaurandoPadrao = false);
    }
  }

  void _mostrarMensagem(String texto, {bool erro = false}) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
        backgroundColor: erro ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<TiposRecebimento> tipos = _tiposOrdenados;
    final int ativos = tipos.where((TiposRecebimento item) => item.ativo).length;
    final int imediatos = tipos
        .where((TiposRecebimento item) => item.naturezaRecebimento.trim().toUpperCase() == 'IMEDIATO')
        .length;
    final int futuros = tipos
        .where((TiposRecebimento item) => item.naturezaRecebimento.trim().toUpperCase() == 'FUTURO')
        .length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          SixWebEntry(
            order: 0,
            child: _ResumoFormasRecebimentoCard(
              total: tipos.length,
              ativos: ativos,
              imediatos: imediatos,
              futuros: futuros,
            ),
          ),
          const SizedBox(height: 12),
          if (_carregando && _tipos.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (_erro != null && _tipos.isNotEmpty) ...<Widget>[
            _InlineErrorCard(mensagem: _erro!, onRetry: _carregando ? null : _carregarTipos),
            const SizedBox(height: 10),
          ],
          Expanded(child: _buildBody(tipos)),
          const SizedBox(height: 12),
          _buildBottomBar(total: tipos.length, ativos: ativos),
        ],
      ),
    );
  }

  Widget _buildBody(List<TiposRecebimento> tipos) {
    if (_carregando && _tipos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          const SixBackendLoading(
            title: 'Carregando formas de recebimento',
            subtitle: 'Sincronizando as configurações da empresa no backend.',
            animation: SixBackendLoadingAnimation.skeletonPulse,
            leadingIcon: Icons.payments_rounded,
          ),
          const SizedBox(height: 12),
          ...List<Widget>.generate(
            4,
            (int index) => Padding(
              padding: EdgeInsets.only(bottom: index == 3 ? 0 : 10),
              child: const SixWebLoadingBlock(height: 132),
            ),
          ),
        ],
      );
    }

    if (_erro != null && _tipos.isEmpty) {
      return _ErrorStateCard(mensagem: _erro!, onRetry: _carregarTipos);
    }

    if (tipos.isEmpty) return _EmptyStateCard(onReload: _carregarTipos);

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: tipos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final TiposRecebimento tipo = tipos[index];
        return SixWebEntry(
          order: index + 2,
          child: _TipoRecebimentoCard(
            tipo: tipo,
            salvando: _salvandoCodigo == tipo.codigoTipo,
            onEditar: () => _editarTipo(tipo),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar({required int total, required int ativos}) {
    final ThemeData theme = Theme.of(context);
    final bool bloqueado = _restaurandoPadrao || _salvandoCodigo != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compacto = constraints.maxWidth < 820;
          final Widget info = Text(
            'Tipos carregados: $total • Ativos: $ativos',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          );
          final Widget actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: (_carregando || bloqueado) ? null : () => _carregarTipos(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Atualizar'),
              ),
              FilledButton.icon(
                onPressed: (_carregando || bloqueado || _tipos.isEmpty) ? null : _restaurarPadrao,
                icon: _restaurandoPadrao
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.restart_alt_rounded),
                label: const Text('Restaurar padrão'),
              ),
            ],
          );
          if (compacto) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[info, const SizedBox(height: 10), actions],
            );
          }
          return Row(children: <Widget>[Expanded(child: info), const SizedBox(width: 12), actions]);
        },
      ),
    );
  }

  int _numeroTipo(String codigoTipo) {
    final RegExpMatch? match = RegExp(r'^tipo(\d+)$').firstMatch(codigoTipo.trim().toLowerCase());
    if (match == null) return 999;
    return int.tryParse(match.group(1) ?? '') ?? 999;
  }
}

class _ResumoFormasRecebimentoCard extends StatelessWidget {
  const _ResumoFormasRecebimentoCard({
    required this.total,
    required this.ativos,
    required this.imediatos,
    required this.futuros,
  });

  final int total;
  final int ativos;
  final int imediatos;
  final int futuros;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compacto = constraints.maxWidth < 860;
          final List<_MiniMetric> metricas = <_MiniMetric>[
            _MiniMetric(icon: Icons.payments_rounded, label: 'Tipos configurados', value: '$total'),
            _MiniMetric(icon: Icons.verified_rounded, label: 'Ativos', value: '$ativos'),
            _MiniMetric(icon: Icons.flash_on_rounded, label: 'Natureza imediata', value: '$imediatos'),
            _MiniMetric(icon: Icons.schedule_rounded, label: 'Natureza futura', value: '$futuros'),
          ];
          if (compacto) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ResumoHeader(theme: theme),
                const SizedBox(height: 14),
                Wrap(spacing: 10, runSpacing: 10, children: metricas.map((m) => _MiniMetricCard(data: m)).toList()),
              ],
            );
          }
          return Row(
            children: <Widget>[
              Expanded(child: _ResumoHeader(theme: theme)),
              const SizedBox(width: 16),
              ...metricas.map((m) => Padding(padding: const EdgeInsets.only(left: 10), child: _MiniMetricCard(data: m))),
            ],
          );
        },
      ),
    );
  }
}

class _ResumoHeader extends StatelessWidget {
  const _ResumoHeader({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.payments_rounded, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Formas de recebimento', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                'Configure os tipos exibidos no PDV, agenda financeira e recebimentos.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniMetric {
  const _MiniMetric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({required this.data});
  final _MiniMetric data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(data.icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(data.value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                Text(data.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipoRecebimentoCard extends StatelessWidget {
  const _TipoRecebimentoCard({required this.tipo, required this.salvando, required this.onEditar});

  final TiposRecebimento tipo;
  final bool salvando;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color cor = _parseColor(tipo.corHex, fallback: theme.colorScheme.primary);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: cor.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
            child: Icon(_resolverIcone(tipo.icone, naturezaRecebimento: tipo.naturezaRecebimento), color: cor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(tipo.descricaoExibicao, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    _Badge(text: tipo.codigoTipo.toUpperCase()),
                    _Badge(text: tipo.naturezaRecebimento),
                    _Badge(text: tipo.ativo ? 'Ativo' : 'Inativo', destaque: tipo.ativo),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ordem ${tipo.ordemExibicao} • ${tipo.aceitaParcelamento ? 'Aceita parcelamento' : 'Sem parcelamento'} • ${tipo.exigeCliente ? 'Exige cliente' : 'Cliente opcional'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          salvando
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : OutlinedButton.icon(onPressed: onEditar, icon: const Icon(Icons.edit_outlined), label: const Text('Editar')),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.destaque = false});
  final String text;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: destaque ? const Color(0xFFDCFCE7) : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: destaque ? const Color(0xFF166534) : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _TipoRecebimentoEditDialog extends StatefulWidget {
  const _TipoRecebimentoEditDialog({required this.tipo});
  final TiposRecebimento tipo;

  @override
  State<_TipoRecebimentoEditDialog> createState() => _TipoRecebimentoEditDialogState();
}

class _TipoRecebimentoEditDialogState extends State<_TipoRecebimentoEditDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _descricaoController;
  late final TextEditingController _ordemController;
  late final TextEditingController _corController;
  late bool _ativo;
  late bool _aceitaParcelamento;
  late bool _exigeCliente;
  late String _natureza;
  late String _icone;

  static const List<String> _naturezas = <String>['IMEDIATO', 'FUTURO'];
  static const List<String> _iconesDisponiveis = <String>[
    'payments',
    'money',
    'cash',
    'pix',
    'credit_card',
    'debit_card',
    'boleto',
    'receipt',
    'schedule',
    'wallet',
  ];

  @override
  void initState() {
    super.initState();
    _descricaoController = TextEditingController(text: widget.tipo.descricaoExibicao);
    _ordemController = TextEditingController(text: widget.tipo.ordemExibicao.toString());
    _corController = TextEditingController(text: widget.tipo.corHex.trim().isEmpty ? '#2563EB' : widget.tipo.corHex);
    _ativo = widget.tipo.ativo;
    _aceitaParcelamento = widget.tipo.aceitaParcelamento;
    _exigeCliente = widget.tipo.exigeCliente;
    _natureza = _naturezas.contains(widget.tipo.naturezaRecebimento.toUpperCase())
        ? widget.tipo.naturezaRecebimento.toUpperCase()
        : 'IMEDIATO';
    _icone = _normalizarIconeParaEdicao(widget.tipo.icone);
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _ordemController.dispose();
    _corController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Editar forma de recebimento'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('Código: ${widget.tipo.codigoTipo.toUpperCase()}', style: theme.textTheme.labelLarge),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descricaoController,
                  decoration: const InputDecoration(labelText: 'Descrição de exibição', border: OutlineInputBorder()),
                  validator: (String? value) => (value ?? '').trim().isEmpty ? 'Informe a descrição.' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _ordemController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Ordem', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _corController,
                        decoration: const InputDecoration(labelText: 'Cor HEX', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _natureza,
                  decoration: const InputDecoration(labelText: 'Natureza', border: OutlineInputBorder()),
                  items: _naturezas.map((String item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
                  onChanged: (String? value) {
                    if (value != null) setState(() => _natureza = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _iconesDisponiveis.contains(_icone) ? _icone : 'payments',
                  decoration: const InputDecoration(labelText: 'Ícone', border: OutlineInputBorder()),
                  items: _iconesDisponiveis
                      .map((String item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (String? value) {
                    if (value != null) setState(() => _icone = value);
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ativo'),
                  value: _ativo,
                  onChanged: (bool value) => setState(() => _ativo = value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aceita parcelamento'),
                  value: _aceitaParcelamento,
                  onChanged: (bool value) => setState(() => _aceitaParcelamento = value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Exige cliente'),
                  value: _exigeCliente,
                  onChanged: (bool value) => setState(() => _exigeCliente = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton.icon(onPressed: _salvar, icon: const Icon(Icons.save_outlined), label: const Text('Salvar')),
      ],
    );
  }

  void _salvar() {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    Navigator.of(context).pop(
      widget.tipo.copyWith(
        descricaoExibicao: _descricaoController.text.trim(),
        naturezaRecebimento: _natureza,
        ativo: _ativo,
        aceitaParcelamento: _aceitaParcelamento,
        exigeCliente: _exigeCliente,
        ordemExibicao: int.tryParse(_ordemController.text.trim()) ?? widget.tipo.ordemExibicao,
        corHex: _corController.text.trim().isEmpty ? '#2563EB' : _corController.text.trim(),
        icone: _icone,
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.mensagem, required this.onRetry});
  final String mensagem;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _MessageCard(
      icon: Icons.warning_amber_rounded,
      title: mensagem,
      actionLabel: 'Tentar novamente',
      onAction: onRetry,
    );
  }
}

class _ErrorStateCard extends StatelessWidget {
  const _ErrorStateCard({required this.mensagem, required this.onRetry});
  final String mensagem;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _MessageCard(
        icon: Icons.cloud_off_rounded,
        title: mensagem,
        actionLabel: 'Tentar novamente',
        onAction: onRetry,
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.onReload});
  final VoidCallback? onReload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _MessageCard(
        icon: Icons.payments_outlined,
        title: 'Nenhuma forma de recebimento configurada.',
        actionLabel: 'Atualizar',
        onAction: onReload,
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.title, required this.actionLabel, required this.onAction});
  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.primary, size: 36),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: onAction, icon: const Icon(Icons.refresh_rounded), label: Text(actionLabel)),
        ],
      ),
    );
  }
}

IconData _resolverIcone(String value, {required String naturezaRecebimento}) {
  final String normalized = value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  const Map<String, IconData> icones = <String, IconData>{
    'payments': Icons.payments_rounded,
    'paymentsrounded': Icons.payments_rounded,
    'money': Icons.attach_money_rounded,
    'attachmoney': Icons.attach_money_rounded,
    'attachmoneyrounded': Icons.attach_money_rounded,
    'cash': Icons.money_rounded,
    'pix': Icons.qr_code_2_rounded,
    'qrcode2': Icons.qr_code_2_rounded,
    'qrcode2rounded': Icons.qr_code_2_rounded,
    'creditcard': Icons.credit_card_rounded,
    'creditcardrounded': Icons.credit_card_rounded,
    'debitcard': Icons.credit_card_rounded,
    'boleto': Icons.receipt_long_rounded,
    'receipt': Icons.receipt_long_rounded,
    'receiptlong': Icons.receipt_long_rounded,
    'receiptlongrounded': Icons.receipt_long_rounded,
    'invoice': Icons.receipt_long_rounded,
    'schedule': Icons.schedule_rounded,
    'schedulerounded': Icons.schedule_rounded,
    'future': Icons.schedule_rounded,
    'accountbalancewallet': Icons.account_balance_wallet_rounded,
    'accountbalancewalletrounded': Icons.account_balance_wallet_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
  };
  final IconData? icon = icones[normalized];
  if (icon != null) return icon;
  if (naturezaRecebimento.trim().toUpperCase() == 'FUTURO') return Icons.schedule_rounded;
  return Icons.payments_rounded;
}

String _normalizarIconeParaEdicao(String value) {
  final String normalized = value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (normalized.contains('pix') || normalized.contains('qrcode')) return 'pix';
  if (normalized.contains('credit')) return 'credit_card';
  if (normalized.contains('debit')) return 'debit_card';
  if (normalized.contains('boleto') || normalized.contains('receipt') || normalized.contains('invoice')) return 'boleto';
  if (normalized.contains('schedule') || normalized.contains('future')) return 'schedule';
  if (normalized.contains('wallet') || normalized.contains('accountbalance')) return 'wallet';
  if (normalized.contains('money')) return 'money';
  if (normalized.contains('cash')) return 'cash';
  return 'payments';
}

Color _parseColor(String value, {required Color fallback}) {
  final String text = value.trim().replaceAll('#', '');
  if (text.length == 6) {
    final int? rgb = int.tryParse(text, radix: 16);
    if (rgb != null) return Color(0xFF000000 | rgb);
  }
  if (text.length == 8) {
    final int? argb = int.tryParse(text, radix: 16);
    if (argb != null) return Color(argb);
  }
  return fallback;
}
