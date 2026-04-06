import 'package:appplanilha/presentation/screens/produto_lista_sub_painel_web.dart';
import 'package:appplanilha/sub_painel_cadastro_produto.dart';
import 'package:appplanilha/sub_painel_configuracoes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/produto_model.dart';
import '../../top_navigation_bar.dart';

class OrdemServicoWeb extends StatefulWidget {
  const OrdemServicoWeb({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<OrdemServicoWeb> createState() => _OrdemServicoWebState();
}

class _OrdemServicoWebState extends State<OrdemServicoWeb> {
  final PageController _page = PageController();
  int _step = 0;

  final _os = TextEditingController(text: 'OS-2026-00458');
  final _cliente = TextEditingController(text: 'Marina Oliveira');
  final _telefone = TextEditingController(text: '(47) 99999-0001');
  final _email = TextEditingController(text: 'marina.oliveira@email.com');
  final _doc = TextEditingController(text: '123.456.789-00');
  final _equip = TextEditingController(text: 'iPhone 13 128GB');
  final _marca = TextEditingController(text: 'Apple');
  final _modelo = TextEditingController(text: 'A2633');
  final _serial = TextEditingController(text: 'SN-IP13-009988');
  final _acessorios = TextEditingController(
    text: 'Capa, película e cabo USB-C',
  );
  final _defeito = TextEditingController(
    text:
        'Tela sem imagem após queda. Cliente relata vibração e sons de notificações.',
  );
  final _diagnostico = TextEditingController(
    text:
        'Display comprometido e conector com folga. Recomendado troca de display e testes finais.',
  );
  final _obs = TextEditingController(
    text:
        'Cliente autorizou contato por WhatsApp. Priorizar fechamento em até 48h.',
  );
  final _prazo = TextEditingController(text: '2 dias úteis');
  final _garantia = TextEditingController(text: '90 dias para peças e serviço');
  final _tecnico = TextEditingController(text: 'André Souza');
  final _checkin = TextEditingController(
    text: 'Aparelho recebido ligado, sem imagem, com leves marcas laterais.',
  );
  final _assinante = TextEditingController(text: 'Marina Oliveira');

  final List<String> _status = [
    'Aberta',
    'Triagem',
    'Aguardando aprovação',
    'Aguardando peça',
    'Em execução',
    'Pronta para entrega',
    'Finalizada',
  ];
  final List<String> _prioridades = ['Baixa', 'Normal', 'Alta', 'Urgente'];
  final List<String> _origens = [
    'Balcão',
    'WhatsApp',
    'Instagram',
    'Site',
    'Indicação',
  ];
  final List<String> _tipos = [
    'Assistência técnica',
    'Manutenção preventiva',
    'Instalação',
    'Garantia',
    'Diagnóstico',
  ];

  String _statusSel = 'Aguardando aprovação';
  String _prioridadeSel = 'Alta';
  String _origemSel = 'WhatsApp';
  String _tipoSel = 'Assistência técnica';
  bool _autorizaContato = true;
  bool _aprovou = true;
  bool _sinal = true;
  bool _reserva = false;
  bool _entrega = false;
  bool _assinou = false;
  DateTime? _assinadoEm;
  List<Offset?> _pontos = <Offset?>[];

  final List<Map<String, dynamic>> _check = [
    {
      't': 'Liga normalmente',
      'd': 'Equipamento energiza e apresenta sinais básicos de vida.',
      'ok': true,
    },
    {
      't': 'Tela apresenta imagem',
      'd': 'Display principal está funcional.',
      'ok': false,
    },
    {
      't': 'Touch responde',
      'd': 'Touch responde corretamente em toda a área.',
      'ok': false,
    },
    {
      't': 'Carregamento funcional',
      'd': 'Conector e bateria respondem no teste inicial.',
      'ok': true,
    },
    {
      't': 'Sem indício de oxidação',
      'd': 'Verificação visual inicial da placa e conectores.',
      'ok': true,
    },
  ];

  final List<Map<String, dynamic>> _tarefas = [
    {
      't': 'Triagem inicial concluída',
      'r': 'André Souza',
      's': 'Concluída',
      'd': '15 min',
      'ok': true,
    },
    {
      't': 'Teste de display provisório',
      'r': 'André Souza',
      's': 'Em andamento',
      'd': '20 min',
      'ok': false,
    },
    {
      't': 'Validação do Face ID',
      'r': 'Marcos Lima',
      's': 'Pendente',
      'd': '10 min',
      'ok': false,
    },
  ];

  final List<Map<String, dynamic>> _itens = [
    {
      'tipo': 'servico',
      'nome': 'Troca de display OLED premium',
      'det': 'Mão de obra técnica especializada',
      'q': 1,
      'v': 790.0,
      'sel': true,
    },
    {
      'tipo': 'servico',
      'nome': 'Revisão interna e testes finais',
      'det': 'Checklist completo de entrega',
      'q': 1,
      'v': 90.0,
      'sel': true,
    },
    {
      'tipo': 'produto',
      'nome': 'Película de proteção 3D',
      'det': 'Opcional sugerido na entrega',
      'q': 1,
      'v': 49.9,
      'sel': false,
    },
    {
      'tipo': 'produto',
      'nome': 'Capa magnética premium',
      'det': 'Upsell no fechamento',
      'q': 1,
      'v': 79.9,
      'sel': false,
    },
  ];

  final List<Map<String, dynamic>> _timeline = [
    {
      't': 'OS aberta no balcão',
      'd': 'Cliente identificado e aparelho recebido para triagem.',
      'h': 'Hoje • 09:14',
      'i': Icons.add_task,
    },
    {
      't': 'Diagnóstico registrado',
      'd': 'Hipótese principal validada e orçamento preparado.',
      'h': 'Hoje • 09:42',
      'i': Icons.medical_information_outlined,
    },
    {
      't': 'Mensagem enviada ao cliente',
      'd': 'Resumo do orçamento enviado por WhatsApp.',
      'h': 'Hoje • 09:47',
      'i': Icons.chat_bubble_outline,
    },
  ];

  final List<Map<String, dynamic>> _canais = [
    {'t': 'WhatsApp', 'sel': true, 'i': Icons.chat},
    {'t': 'E-mail', 'sel': true, 'i': Icons.email_outlined},
    {'t': 'Telegram', 'sel': false, 'i': Icons.send},
    {'t': 'SMS', 'sel': false, 'i': Icons.sms_outlined},
  ];

  List<Map<String, dynamic>> get _steps => const [
    {
      't': 'Abertura',
      'd': 'Status, origem e contexto',
      'i': Icons.assignment_add,
    },
    {
      't': 'Cliente e item',
      'd': 'Cadastro e check-in',
      'i': Icons.devices_other_outlined,
    },
    {
      't': 'Diagnóstico',
      'd': 'Defeito e checklist',
      'i': Icons.medical_information_outlined,
    },
    {
      't': 'Execução',
      'd': 'Tarefas e responsável',
      'i': Icons.engineering_outlined,
    },
    {
      't': 'Itens e custos',
      'd': 'Peças, serviços e aprovação',
      'i': Icons.inventory_2_outlined,
    },
    {
      't': 'Entrega e assinatura',
      'd': 'Prazo, link, QR e aceite',
      'i': Icons.verified_outlined,
    },
  ];

  @override
  void dispose() {
    for (final c in [
      _os,
      _cliente,
      _telefone,
      _email,
      _doc,
      _equip,
      _marca,
      _modelo,
      _serial,
      _acessorios,
      _defeito,
      _diagnostico,
      _obs,
      _prazo,
      _garantia,
      _tecnico,
      _checkin,
      _assinante,
    ]) {
      c.dispose();
    }
    _page.dispose();
    super.dispose();
  }

  String _money(double v) => 'R\$ ${v.toStringAsFixed(2)}';

  String _link() =>
      'https://sixapp.mock/ordem-servico/${_os.text.trim().toLowerCase().replaceAll(' ', '-').ifEmpty('os-demo')}';

  double _total() => _itens
      .where((e) => e['sel'] == true)
      .fold(0.0, (a, e) => a + ((e['v'] as num).toDouble() * (e['q'] as int)));

  double _sinalValor() => _sinal ? _total() * .30 : 0;

  int _qtd() => _itens
      .where((e) => e['sel'] == true)
      .fold(0, (a, e) => a + (e['q'] as int));

  int _okCheck() => _check.where((e) => e['ok'] == true).length;

  int _okTarefas() => _tarefas.where((e) => e['ok'] == true).length;

  bool get _last => _step == _steps.length - 1;

  String _dt(DateTime? d) =>
      d == null
          ? '-'
          : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _go(int i) {
    if (i < 0 || i >= _steps.length) return;
    setState(() => _step = i);
    _page.animateToPage(
      i,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_step == 0) {
      if (widget.embedded) {
        widget.onBack?.call();
      } else {
        Navigator.of(context).maybePop();
      }
      return;
    }
    _go(_step - 1);
  }

  void _next() {
    if (_last) {
      _msg(
        'Fluxo concluído',
        _assinou
            ? 'A OS foi concluída com assinatura digital mockada.'
            : 'A OS foi concluída. Você ainda pode coletar a assinatura do cliente neste fluxo.',
      );
      return;
    }
    _go(_step + 1);
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _link()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link do resumo copiado para a área de transferência.'),
      ),
    );
  }

  Future<void> _pickProduto() async {
    final ProdutoModel? r = await showDialog<ProdutoModel>(
      context: context,
      builder:
          (c) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              width: MediaQuery.of(c).size.width * .8,
              height: MediaQuery.of(c).size.height * .8,
              child: SubPainelWebProdutoLista(isSelecao: true),
            ),
          ),
    );
    if (r == null) return;
    setState(() {
      _itens.add({
        'tipo': 'produto',
        'nome': r.nomeProduto,
        'det': 'Produto adicionado manualmente à OS',
        'q': 1,
        'v': (r.precoVenda as num).toDouble(),
        'sel': true,
      });
      _timeline.insert(0, {
        't': 'Produto incluído na OS',
        'd': '${r.nomeProduto} foi adicionado ao fluxo da ordem de serviço.',
        'h': 'Agora',
        'i': Icons.add_box_outlined,
      });
    });
  }

  Future<void> _confirmCancelAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Cancelar tudo'),
            content: const Text(
              'Deseja descartar todo o fluxo da ordem de serviço e voltar para a tela anterior?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(false),
                child: const Text('Continuar editando'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(c).pop(true),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Cancelar tudo'),
              ),
            ],
          ),
    );
    if (ok == true) _cancelAll();
  }

  void _cancelAll() {
    setState(() {
      _step = 0;
      _statusSel = 'Aguardando aprovação';
      _prioridadeSel = 'Alta';
      _origemSel = 'WhatsApp';
      _tipoSel = 'Assistência técnica';
      _autorizaContato = true;
      _aprovou = true;
      _sinal = true;
      _reserva = false;
      _entrega = false;
      _assinou = false;
      _assinadoEm = null;
      _pontos = [];
      _os.text = 'OS-2026-00458';
      _cliente.text = 'Marina Oliveira';
      _telefone.text = '(47) 99999-0001';
      _email.text = 'marina.oliveira@email.com';
      _doc.text = '123.456.789-00';
      _equip.text = 'iPhone 13 128GB';
      _marca.text = 'Apple';
      _modelo.text = 'A2633';
      _serial.text = 'SN-IP13-009988';
      _acessorios.text = 'Capa, película e cabo USB-C';
      _defeito.text =
          'Tela sem imagem após queda. Cliente relata vibração e sons de notificações.';
      _diagnostico.text =
          'Display comprometido e conector com folga. Recomendado troca de display e testes finais.';
      _obs.text =
          'Cliente autorizou contato por WhatsApp. Priorizar fechamento em até 48h.';
      _prazo.text = '2 dias úteis';
      _garantia.text = '90 dias para peças e serviço';
      _tecnico.text = 'André Souza';
      _checkin.text =
          'Aparelho recebido ligado, sem imagem, com leves marcas laterais.';
      _assinante.text = 'Marina Oliveira';
      for (final i in _check) {
        i['ok'] =
            i['t'] == 'Liga normalmente' ||
            i['t'] == 'Carregamento funcional' ||
            i['t'] == 'Sem indício de oxidação';
      }
      for (final t in _tarefas) {
        t['ok'] = t['t'] == 'Triagem inicial concluída';
      }
      _itens
        ..clear()
        ..addAll([
          {
            'tipo': 'servico',
            'nome': 'Troca de display OLED premium',
            'det': 'Mão de obra técnica especializada',
            'q': 1,
            'v': 790.0,
            'sel': true,
          },
          {
            'tipo': 'servico',
            'nome': 'Revisão interna e testes finais',
            'det': 'Checklist completo de entrega',
            'q': 1,
            'v': 90.0,
            'sel': true,
          },
          {
            'tipo': 'produto',
            'nome': 'Película de proteção 3D',
            'det': 'Opcional sugerido na entrega',
            'q': 1,
            'v': 49.9,
            'sel': false,
          },
          {
            'tipo': 'produto',
            'nome': 'Capa magnética premium',
            'det': 'Upsell no fechamento',
            'q': 1,
            'v': 79.9,
            'sel': false,
          },
        ]);
      _timeline
        ..clear()
        ..addAll([
          {
            't': 'OS aberta no balcão',
            'd': 'Cliente identificado e aparelho recebido para triagem.',
            'h': 'Hoje • 09:14',
            'i': Icons.add_task,
          },
          {
            't': 'Diagnóstico registrado',
            'd': 'Hipótese principal validada e orçamento preparado.',
            'h': 'Hoje • 09:42',
            'i': Icons.medical_information_outlined,
          },
          {
            't': 'Mensagem enviada ao cliente',
            'd': 'Resumo do orçamento enviado por WhatsApp.',
            'h': 'Hoje • 09:47',
            'i': Icons.chat_bubble_outline,
          },
        ]);
      for (final c in _canais) {
        c['sel'] = c['t'] == 'WhatsApp' || c['t'] == 'E-mail';
      }
    });
    if (_page.hasClients) _page.jumpToPage(0);
    if (widget.embedded) {
      widget.onBack?.call();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _signDialog() async {
    final nome = TextEditingController(text: _assinante.text);
    List<Offset?> temp = List<Offset?>.from(_pontos);
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => StatefulBuilder(
            builder:
                (c, setM) => AlertDialog(
                  title: const Text('Assinatura digital do cliente'),
                  content: SizedBox(
                    width: 760,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nome,
                          decoration: const InputDecoration(
                            labelText: 'Nome do assinante',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SignaturePad(
                          points: temp,
                          onChanged: (v) => setM(() => temp = v),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'A assinatura fica apenas na memória da tela até a integração com o backend.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(c).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(c).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton.icon(
                      onPressed: () => setM(() => temp = []),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Limpar'),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        if (temp.whereType<Offset>().isEmpty) {
                          ScaffoldMessenger.of(c).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Faça a assinatura antes de salvar.',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.of(c).pop(true);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Salvar assinatura'),
                    ),
                  ],
                ),
          ),
    );
    if (ok == true) {
      setState(() {
        _assinante.text = nome.text.trim();
        _pontos = temp;
        _assinou = true;
        _assinadoEm = DateTime.now();
        _timeline.insert(0, {
          't': 'Assinatura digital coletada',
          'd': 'Cliente revisou o resumo da OS e assinou digitalmente.',
          'h': 'Agora',
          'i': Icons.draw_outlined,
        });
      });
    }
    nome.dispose();
  }

  void _msg(String t, String m) {
    showDialog<void>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: Text(t),
            content: Text(m),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  Widget _tf(TextEditingController c, String l, IconData i, {int lines = 1}) =>
      TextField(
        controller: c,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: l,
          alignLabelWithHint: lines > 1,
          prefixIcon: Icon(i),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onChanged: (_) => setState(() {}),
      );

  Widget _dd<T>(String l, T v, List<T> items, ValueChanged<T?> ch) =>
      DropdownButtonFormField<T>(
        value: v,
        onChanged: ch,
        decoration: InputDecoration(
          labelText: l,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        items:
            items
                .map(
                  (e) =>
                      DropdownMenuItem<T>(value: e, child: Text(e.toString())),
                )
                .toList(),
      );

  Widget _switchCard(
    String t,
    String d,
    bool v,
    ValueChanged<bool> ch,
  ) => SizedBox(
    width: 320,
    child: SwitchListTile(
      value: v,
      onChanged: ch,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(d),
    ),
  );

  Widget _pill(String t, IconData i) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );

  Widget _rowInfo(String t, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            t,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v.isEmpty ? '-' : v,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  Widget _valueRow(String t, double v, {bool strong = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Text(
          t,
          style: TextStyle(
            fontSize: strong ? 16 : 14,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          _money(v),
          style: TextStyle(
            fontSize: strong ? 18 : 14,
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            color:
                strong
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    ),
  );

  Widget _stepCard(String title, String sub, Widget child) => Card(
    elevation: 2,
    shadowColor: Colors.black.withOpacity(.06),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: SizedBox(width: double.infinity, child: child)),
        ],
      ),
    ),
  );

  Widget _stepSummary(String title, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(.10),
          child: Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    ),
  );

  Widget _summary() => Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo da OS',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _rowInfo('OS', _os.text),
                  _rowInfo('Cliente', _cliente.text),
                  _rowInfo('Equipamento', _equip.text),
                  _rowInfo('Status', _statusSel),
                  _rowInfo('Técnico', _tecnico.text),
                  _rowInfo('Prazo', _prazo.text),
                  _rowInfo(
                    'Assinatura',
                    _assinou ? 'Coletada em ${_dt(_assinadoEm)}' : 'Pendente',
                  ),
                  const Divider(height: 28),
                  _stepSummary(
                    'Checklist técnico',
                    '${_okCheck()}/${_check.length}',
                    Icons.fact_check_outlined,
                  ),
                  const SizedBox(height: 12),
                  _stepSummary(
                    'Tarefas concluídas',
                    '${_okTarefas()}/${_tarefas.length}',
                    Icons.task_alt_outlined,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Itens selecionados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._itens.where((e) => e['sel'] == true).map((e) {
                    final q = e['q'] as int;
                    final v = (e['v'] as num).toDouble();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            e['tipo'] == 'produto'
                                ? Icons.inventory_2_outlined
                                : Icons.build_circle_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${e['nome']} ($q x)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _money(v * q),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 26),
                  _valueRow('Qtd. itens', _qtd().toDouble()),
                  _valueRow('Subtotal', _total()),
                  _valueRow('Sinal sugerido', _sinalValor()),
                  const SizedBox(height: 10),
                  _valueRow('Total', _total(), strong: true),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _copyLink,
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('Copiar link do cliente'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _history() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Linha do tempo',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ..._timeline.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    e['i'] as IconData,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e['t'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(e['d'] as String),
                      const SizedBox(height: 2),
                      Text(
                        e['h'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _stepAbertura() => _stepCard(
    '1. Abertura da ordem de serviço',
    'Registre o contexto da OS, o status inicial, o canal de entrada e a criticidade da demanda.',
    SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _tf(_os, 'Número da OS', Icons.tag_outlined)),
              const SizedBox(width: 14),
              Expanded(
                child: _dd<String>('Status atual', _statusSel, _status, (v) {
                  if (v != null) setState(() => _statusSel = v);
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _dd<String>('Origem', _origemSel, _origens, (v) {
                  if (v != null) setState(() => _origemSel = v);
                }),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _dd<String>('Prioridade', _prioridadeSel, _prioridades, (
                  v,
                ) {
                  if (v != null) setState(() => _prioridadeSel = v);
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _dd<String>('Tipo de atendimento', _tipoSel, _tipos, (v) {
            if (v != null) setState(() => _tipoSel = v);
          }),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(.06),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _pill('Fluxo guiado', Icons.auto_awesome),
                _pill('QR para o cliente', Icons.qr_code_rounded),
                _pill('Assinatura digital', Icons.draw_rounded),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _stepCliente() => _stepCard(
    '2. Cliente, equipamento e check-in',
    'Centralize os dados da pessoa, do item recebido e os registros de entrada da operação.',
    SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _tf(_cliente, 'Nome do cliente', Icons.person_outline),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _tf(_doc, 'CPF / Documento', Icons.badge_outlined),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _tf(
                  _telefone,
                  'Telefone / WhatsApp',
                  Icons.phone_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: _tf(_email, 'E-mail', Icons.email_outlined)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _tf(
                  _equip,
                  'Equipamento / item',
                  Icons.devices_other_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _tf(
                  _serial,
                  'Serial / IMEI / Patrimônio',
                  Icons.confirmation_number_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _tf(_marca, 'Marca', Icons.business_outlined)),
              const SizedBox(width: 14),
              Expanded(
                child: _tf(_modelo, 'Modelo / versão', Icons.category_outlined),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _tf(_acessorios, 'Acessórios entregues', Icons.cable_outlined),
          const SizedBox(height: 14),
          _tf(
            _checkin,
            'Observações de check-in',
            Icons.rule_folder_outlined,
            lines: 3,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _switchCard(
                'Cliente autoriza contato',
                'Permite envio de status e aprovações durante a OS.',
                _autorizaContato,
                (v) => setState(() => _autorizaContato = v),
              ),
              _switchCard(
                'Equipamento reserva',
                'Separar unidade reserva enquanto a OS estiver ativa.',
                _reserva,
                (v) => setState(() => _reserva = v),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _stepDiagnostico() => _stepCard(
    '3. Diagnóstico e validação técnica',
    'Registre o defeito, a hipótese técnica e o checklist de entrada com linguagem clara para a equipe.',
    SingleChildScrollView(
      child: Column(
        children: [
          _tf(
            _defeito,
            'Defeito relatado pelo cliente',
            Icons.report_problem_outlined,
            lines: 4,
          ),
          const SizedBox(height: 14),
          _tf(
            _diagnostico,
            'Diagnóstico técnico / parecer inicial',
            Icons.engineering_outlined,
            lines: 4,
          ),
          const SizedBox(height: 14),
          _tf(
            _obs,
            'Observações internas',
            Icons.sticky_note_2_outlined,
            lines: 3,
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Checklist de entrada',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          ..._check.map((e) {
            final ok = e['ok'] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => e['ok'] = !ok),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          ok
                              ? Colors.green.withOpacity(.30)
                              : Theme.of(context).colorScheme.outlineVariant,
                    ),
                    color:
                        ok
                            ? Colors.green.withOpacity(.08)
                            : Theme.of(context).colorScheme.surface,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        ok ? Icons.check_circle : Icons.radio_button_unchecked,
                        color:
                            ok
                                ? Colors.green
                                : Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e['t'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(e['d'] as String),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    ),
  );

  Widget _stepExecucao() => _stepCard(
    '4. Execução, técnico e progresso operacional',
    'Distribua atividades, acompanhe andamento e mantenha a OS atualizada para a equipe e para o atendimento.',
    SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _tf(
                  _tecnico,
                  'Técnico responsável',
                  Icons.person_pin_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _dd<String>('Status da OS', _statusSel, _status, (v) {
                  if (v != null) setState(() => _statusSel = v);
                }),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tarefas da execução',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          ..._tarefas.map((e) {
            final ok = e['ok'] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color:
                      ok
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(.08)
                          : Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color:
                        ok
                            ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(.40)
                            : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: ok,
                      onChanged: (v) => setState(() => e['ok'] = v ?? false),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e['t'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              _pill(e['r'] as String, Icons.person_outline),
                              _pill(e['s'] as String, Icons.flag_outlined),
                              _pill(e['d'] as String, Icons.schedule_outlined),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    ),
  );

  Widget _stepItens() => _stepCard(
    '5. Itens, custos e aprovação do cliente',
    'Componha a OS com serviços e peças, permita ajustes e deixe a proposta pronta para aprovação e faturamento.',
    Column(
      children: [
        Row(
          children: [
            FilledButton.icon(
              onPressed: _pickProduto,
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('Adicionar produto'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed:
                  () => _msg(
                    'Sugestão futura',
                    'No futuro, aqui você poderá buscar serviços padronizados, kits e bundles por categoria.',
                  ),
              icon: const Icon(Icons.build_outlined),
              label: const Text('Adicionar serviço'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: _itens.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (c, i) {
              final e = _itens[i];
              final sel = e['sel'] == true;
              final q = e['q'] as int;
              final v = (e['v'] as num).toDouble();
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color:
                      sel
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(.08)
                          : Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color:
                        sel
                            ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(.40)
                            : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: sel,
                      onChanged: (x) => setState(() => e['sel'] = x ?? false),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                e['tipo'] == 'produto'
                                    ? Icons.inventory_2_outlined
                                    : Icons.build_circle_outlined,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e['nome'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(e['det'] as String),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (q > 1) setState(() => e['q'] = q - 1);
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$q',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          onPressed: () => setState(() => e['q'] = q + 1),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: Text(
                        _money(v * q),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _switchCard(
              'Diagnóstico aprovado',
              'Cliente já aprovou a continuidade da execução.',
              _aprovou,
              (v) => setState(() => _aprovou = v),
            ),
            _switchCard(
              'Solicitar sinal',
              'Reserva de peça e início do serviço após pagamento parcial.',
              _sinal,
              (v) => setState(() => _sinal = v),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _cardQr() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo para o cliente',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'O cliente pode abrir este resumo no celular, revisar as informações da OS e assinar digitalmente no fluxo mockado.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (c, bx) {
            final compact = bx.maxWidth < 720;
            final qr = Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                children: [
                  _FakeQrCode(data: _link(), size: 164),
                  const SizedBox(height: 10),
                  Text(
                    'QR do resumo da OS',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            );
            final info = Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rowInfo('Link', _link()),
                    _rowInfo('Cliente', _cliente.text),
                    _rowInfo('Contato', _telefone.text),
                    _rowInfo('Status', _statusSel),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: _copyLink,
                          icon: const Icon(Icons.copy_outlined),
                          label: const Text('Copiar link'),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              () => _msg(
                                'Prévia do resumo do cliente',
                                'Neste fluxo mockado, este link abrirá uma página de resumo da OS com aceite digital do cliente.',
                              ),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Pré-visualizar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
            if (compact)
              return Column(children: [qr, const SizedBox(height: 12), info]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [qr, const SizedBox(width: 14), info],
            );
          },
        ),
      ],
    ),
  );

  Widget _cardSign() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assinatura digital do cliente',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          _assinou
              ? 'Assinatura coletada com sucesso neste mock. O fluxo já está pronto para futura persistência no backend.'
              : 'Ainda não foi coletada. Use o botão abaixo para abrir o quadro de assinatura do cliente.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        if (_assinou)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Assinatura realizada por ${_assinante.text.trim().isEmpty ? 'cliente' : _assinante.text.trim()} em ${_dt(_assinadoEm)}.',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: _signDialog,
              icon: Icon(
                _assinou ? Icons.edit_note_rounded : Icons.draw_rounded,
              ),
              label: Text(
                _assinou ? 'Refazer assinatura' : 'Coletar assinatura',
              ),
            ),
            if (_assinou)
              OutlinedButton.icon(
                onPressed:
                    () => setState(() {
                      _assinou = false;
                      _assinadoEm = null;
                      _pontos = [];
                    }),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remover assinatura'),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _stepEntrega() => _stepCard(
    '6. Entrega, link, QR e assinatura digital',
    'Finalize a OS com prazo, garantia, compartilhamento do resumo e aceite digital do cliente, sem depender do backend por enquanto.',
    SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _tf(_prazo, 'Prazo estimado', Icons.schedule_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _tf(_garantia, 'Garantia', Icons.verified_outlined),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Canais de comunicação',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                _canais.map((e) {
                  final sel = e['sel'] == true;
                  return FilterChip(
                    selected: sel,
                    avatar: Icon(
                      e['i'] as IconData,
                      size: 18,
                      color:
                          sel
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(e['t'] as String),
                    onSelected: (v) => setState(() => e['sel'] = v),
                  );
                }).toList(),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _switchCard(
                'Entrega em domicílio',
                'Preparar rota, taxa e confirmação de recebimento.',
                _entrega,
                (v) => setState(() => _entrega = v),
              ),
              _switchCard(
                'Autorizar contato automático',
                'Preparar futuras notificações por WhatsApp, e-mail e Telegram.',
                _autorizaContato,
                (v) => setState(() => _autorizaContato = v),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _cardQr(),
          const SizedBox(height: 18),
          _cardSign(),
        ],
      ),
    ),
  );

  Widget _header(ThemeData theme, bool compact) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 14 : 18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.primary.withOpacity(.08),
          theme.colorScheme.surfaceContainerHighest.withOpacity(.65),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: theme.colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(
                    Icons.assignment_turned_in_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Fluxo de Ordem de Serviço',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            _pill(
              'Etapa ${_step + 1}/${_steps.length}',
              Icons.view_carousel_outlined,
            ),
            _pill(_statusSel, Icons.flag_outlined),
            _pill(_prioridadeSel, Icons.bolt_outlined),
            if (_assinou) _pill('Assinada', Icons.verified_rounded),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'O fluxo atual foi mantido e refinado com o que realmente agrega: cancelamento rápido, compartilhamento por link e QR, e coleta de assinatura digital do cliente sem depender de backend neste momento.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: compact ? 12 : 18),
        SizedBox(
          height: compact ? 96 : 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _steps.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (c, i) {
              final s = _steps[i];
              final sel = i == _step;
              final done = i < _step;
              return InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => _go(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: compact ? 220 : 248,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 16,
                    vertical: compact ? 10 : 14,
                  ),
                  decoration: BoxDecoration(
                    color:
                        sel
                            ? theme.colorScheme.primary
                            : done
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color:
                          sel
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                      width: sel ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(sel ? .10 : .04),
                        blurRadius: sel ? 18 : 8,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            sel
                                ? Colors.white
                                : done
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                        foregroundColor:
                            sel
                                ? theme.colorScheme.primary
                                : done
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                        child: Icon(s['i'] as IconData, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['t'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 15,
                                height: 1.1,
                                color:
                                    sel
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s['d'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                height: 1.15,
                                color:
                                    sel
                                        ? Colors.white.withOpacity(.90)
                                        : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: _confirmCancelAll,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Cancelar tudo e voltar'),
            ),
            OutlinedButton.icon(
              onPressed: _copyLink,
              icon: const Icon(Icons.link_rounded),
              label: const Text('Copiar link do resumo'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _navBar() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back),
              label: Text(_step == 0 ? 'Sair' : 'Voltar'),
            ),
            OutlinedButton.icon(
              onPressed:
                  () => _msg(
                    'Salvar rascunho',
                    'No futuro, aqui você poderá salvar a ordem de serviço em andamento sem concluir o fluxo.',
                  ),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar rascunho'),
            ),
            OutlinedButton.icon(
              onPressed: _confirmCancelAll,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Cancelar tudo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade200),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Etapa ${_step + 1} de ${_steps.length}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            FilledButton.icon(
              onPressed: _next,
              icon: Icon(
                _last ? Icons.check_circle_outline : Icons.arrow_forward,
              ),
              label: Text(_last ? 'Concluir' : 'Próxima etapa'),
              style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = <Widget>[
      _stepAbertura(),
      _stepCliente(),
      _stepDiagnostico(),
      _stepExecucao(),
      _stepItens(),
      _stepEntrega(),
    ];

    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (c, bx) {
              final compactH = bx.maxHeight < 760;
              final compactW = bx.maxWidth < 1250;
              return Column(
                children: [
                  _header(theme, compactH),
                  SizedBox(height: compactH ? 12 : 18),
                  Expanded(
                    child:
                        compactW
                            ? Column(
                              children: [
                                Expanded(
                                  child: PageView(
                                    controller: _page,
                                    onPageChanged:
                                        (i) => setState(() => _step = i),
                                    children: pages,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 320,
                                  child: Row(
                                    children: [
                                      Expanded(child: _summary()),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: _history(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                            : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: PageView(
                                    controller: _page,
                                    onPageChanged:
                                        (i) => setState(() => _step = i),
                                    children: pages,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                SizedBox(
                                  width: 390,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(child: _summary()),
                                      const SizedBox(height: 14),
                                      Flexible(
                                        child: SingleChildScrollView(
                                          child: _history(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                  ),
                  SizedBox(height: compactH ? 10 : 16),
                  _navBar(),
                ],
              );
            },
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return Container(
        color: theme.colorScheme.surfaceContainerLowest,
        child: body,
      );
    }

    return Scaffold(
      appBar: TopNavigationBar(
        items: <TopNavItemData>[
          TopNavItemData(
            title: 'Início',
            subItems: const <String>[
              'Preferências do Sistema',
              'Painel Administrativo',
            ],
            onSelect: (v) {
              if (v == 'Painel Administrativo')
                showSubPainelConfiguracoes(context, 'Configurações');
            },
          ),
          const TopNavItemData(
            title: 'Permitir',
            subItems: <String>['Gerenciar Permissões', 'Alterar Configurações'],
          ),
          TopNavItemData(
            title: 'Cadastros',
            subItems: const <String>['Clientes', 'Produtos', 'Fornecedores'],
            onSelect: (v) {
              if (v == 'Produtos')
                showSubPainelCadastroProduto(context, 'Cadastro de Produtos');
            },
          ),
          const TopNavItemData(
            title: 'Relatórios',
            subItems: <String>['Vendas', 'Estoque', 'Financeiro'],
          ),
          const TopNavItemData(
            title: 'Executar',
            subItems: <String>['Processar Pagamentos', 'Fechar Caixa'],
          ),
          const TopNavItemData(
            title: 'Configurações',
            subItems: <String>['Sistema', 'Usuários'],
          ),
          const TopNavItemData(
            title: 'Ajuda',
            subItems: <String>['Suporte', 'Sobre'],
          ),
        ],
        onNotificationPressed: () {},
      ),
      body: body,
    );
  }
}

class _FakeQrCode extends StatelessWidget {
  const _FakeQrCode({required this.data, this.size = 160});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    const d = 21;
    final seed = data.codeUnits.fold<int>(0, (a, b) => a + b);

    bool finder(int r, int c) {
      const f = <List<int>>[
        [0, 0],
        [0, 14],
        [14, 0],
      ];
      for (final p in f) {
        if (r >= p[0] && r < p[0] + 7 && c >= p[1] && c < p[1] + 7) {
          final lr = r - p[0], lc = c - p[1];
          return lr == 0 ||
              lr == 6 ||
              lc == 0 ||
              lc == 6 ||
              (lr >= 2 && lr <= 4 && lc >= 2 && lc <= 4);
        }
      }
      return false;
    }

    bool black(int r, int c) {
      if (finder(r, c)) return true;
      final v = (r * 31 + c * 17 + seed) % 7;
      return v == 0 || v == 2 || v == 5;
    }

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: List.generate(
          d,
          (r) => Expanded(
            child: Row(
              children: List.generate(
                d,
                (c) => Expanded(
                  child: Container(
                    color: black(r, c) ? Colors.black : Colors.white,
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

class _SignaturePad extends StatelessWidget {
  const _SignaturePad({required this.points, required this.onChanged});

  final List<Offset?> points;
  final ValueChanged<List<Offset?>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onPanStart: (d) => onChanged(<Offset?>[...points, d.localPosition]),
          onPanUpdate: (d) => onChanged(<Offset?>[...points, d.localPosition]),
          onPanEnd: (_) => onChanged(<Offset?>[...points, null]),
          child: CustomPaint(
            painter: _SignaturePainter(points: points),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({required this.points});

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = Colors.black87
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      if (a != null && b != null) canvas.drawLine(a, b, p);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) =>
      oldDelegate.points != points;
}

extension _IfEmpty on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
