import 'package:flutter/material.dart';

import '../../data/services/aparencia/aparencia_api_client.dart';
import '../../design_system/helpers/six_theme_resolver.dart';
import '../../domain/models/aparencia_models.dart';
import '../../domain/services/aparencia/aparencia_service.dart';

class CoresFontesWebPage extends StatefulWidget {
  const CoresFontesWebPage({
    super.key,
    this.embedded = false,
    this.onBack,
  });

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<CoresFontesWebPage> createState() => _CoresFontesWebPageState();
}

class _CoresFontesWebPageState extends State<CoresFontesWebPage> {
  late final AparenciaService _aparenciaService;

  bool _carregando = true;
  bool _salvando = false;
  bool _possuiAlteracoes = false;
  bool _salvouComSucesso = false;

  String _temaSelecionado = 'Claro';
  String _densidadeSelecionada = 'Confortável';
  Color _corPrimaria = const Color(0xFF1F3C88);
  Color _corSecundaria = const Color(0xFF5E81F4);
  Color _corDestaque = const Color(0xFF0FA958);
  Color _corAlerta = const Color(0xFFF59E0B);

  ConfiguracaoAparenciaSistema? _configOriginal;
  DensidadeVisualSistema? _densidadeOriginal;

  static const List<Color> _coresSugeridas = <Color>[
    Color(0xFF1F3C88),
    Color(0xFF2563EB),
    Color(0xFF5E81F4),
    Color(0xFF0EA5E9),
    Color(0xFF0FA958),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF7C3AED),
    Color(0xFF111827),
  ];

  @override
  void initState() {
    super.initState();
    _aparenciaService = AparenciaService(apiClient: HttpAparenciaApiClient());
    _carregarAparencia();
  }

  @override
  void dispose() {
    if (!_salvouComSucesso) {
      final ConfiguracaoAparenciaSistema? original = _configOriginal;
      if (original != null) {
        SixThemeResolver().atualizarConfiguracao(original);
      }
      final DensidadeVisualSistema? densidade = _densidadeOriginal;
      if (densidade != null) {
        SixThemeResolver().atualizarDensidade(densidade);
      }
    }
    super.dispose();
  }

  Future<void> _carregarAparencia() async {
    setState(() => _carregando = true);
    try {
      final ConfiguracaoAparenciaSistema config =
          await _aparenciaService.buscarAparencia();
      final DensidadeVisualSistema densidade = SixThemeResolver().densidade;

      _configOriginal = config;
      _densidadeOriginal = densidade;

      setState(() {
        _temaSelecionado = config.tema.label;
        _densidadeSelecionada = densidade.label;
        _corPrimaria = config.paleta.primaria;
        _corSecundaria = config.paleta.secundaria;
        _corDestaque = config.paleta.destaque;
        _corAlerta = config.paleta.alerta;
      });
    } catch (e) {
      _mostrarSnack('Não foi possível carregar cores e fontes: $e', erro: true);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _alterarTema(String? valor) {
    if (valor == null) return;
    setState(() {
      _temaSelecionado = valor;
      _possuiAlteracoes = true;
    });
    _aplicarPreviewGlobal();
  }

  void _alterarDensidade(String? valor) {
    if (valor == null) return;
    setState(() {
      _densidadeSelecionada = valor;
      _possuiAlteracoes = true;
    });
    _aplicarPreviewGlobal();
  }

  void _alterarCor(_TipoCorSistema tipo, Color cor) {
    setState(() {
      switch (tipo) {
        case _TipoCorSistema.primaria:
          _corPrimaria = cor;
          break;
        case _TipoCorSistema.secundaria:
          _corSecundaria = cor;
          break;
        case _TipoCorSistema.destaque:
          _corDestaque = cor;
          break;
        case _TipoCorSistema.alerta:
          _corAlerta = cor;
          break;
      }
      _possuiAlteracoes = true;
    });
    _aplicarPreviewGlobal();
  }

  void _aplicarPreviewGlobal() {
    final PaletaSistema paletaAtual = SixThemeResolver().paleta;
    final ConfiguracaoAparenciaSistema preview = ConfiguracaoAparenciaSistema(
      tema: TemaSistema.fromLabel(_temaSelecionado),
      paleta: PaletaSistema(
        primaria: _corPrimaria,
        secundaria: _corSecundaria,
        destaque: _corDestaque,
        alerta: _corAlerta,
        fundo: paletaAtual.fundo,
        superficie: paletaAtual.superficie,
        textoPrimario: paletaAtual.textoPrimario,
        textoSecundario: paletaAtual.textoSecundario,
      ),
    );

    SixThemeResolver().atualizarConfiguracao(preview);
    SixThemeResolver().atualizarDensidade(
      DensidadeVisualSistema.fromLabel(_densidadeSelecionada),
    );
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    setState(() => _salvando = true);

    try {
      final PaletaSistema paletaAtual = SixThemeResolver().paleta;
      final ConfiguracaoAparenciaSistema configuracao =
          ConfiguracaoAparenciaSistema(
        tema: TemaSistema.fromLabel(_temaSelecionado),
        paleta: PaletaSistema(
          primaria: _corPrimaria,
          secundaria: _corSecundaria,
          destaque: _corDestaque,
          alerta: _corAlerta,
          fundo: paletaAtual.fundo,
          superficie: paletaAtual.superficie,
          textoPrimario: paletaAtual.textoPrimario,
          textoSecundario: paletaAtual.textoSecundario,
        ),
      );

      await _aparenciaService.salvarAparencia(configuracao);
      SixThemeResolver().atualizarConfiguracao(configuracao);
      SixThemeResolver().atualizarDensidade(
        DensidadeVisualSistema.fromLabel(_densidadeSelecionada),
      );

      _configOriginal = configuracao;
      _densidadeOriginal = DensidadeVisualSistema.fromLabel(_densidadeSelecionada);
      _salvouComSucesso = true;

      setState(() => _possuiAlteracoes = false);
      _mostrarSnack('Cores e fontes salvas com sucesso.');
    } catch (e) {
      _mostrarSnack('Erro ao salvar cores e fontes: $e', erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _restaurarPadrao() {
    final PaletaSistema padrao = PaletaSistema.defaultPalette();
    setState(() {
      _temaSelecionado = TemaSistema.claro.label;
      _densidadeSelecionada = DensidadeVisualSistema.confortavel.label;
      _corPrimaria = padrao.primaria;
      _corSecundaria = padrao.secundaria;
      _corDestaque = padrao.destaque;
      _corAlerta = padrao.alerta;
      _possuiAlteracoes = true;
    });
    _aplicarPreviewGlobal();
  }

  void _fechar() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _mostrarSnack(String mensagem, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
        backgroundColor: erro ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget content = Container(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        children: <Widget>[
          _buildHeader(theme),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBody(theme),
            ),
          ),
          _buildActionBar(theme),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(body: SafeArea(child: content));
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[_corPrimaria, _corSecundaria],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.format_paint_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        'Cores e Fontes',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (_possuiAlteracoes) ...<Widget>[
                      const SizedBox(width: 12),
                      _buildPill('Preview não salvo', _corAlerta),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tema, densidade visual e paleta do sistema com prévia em miniatura antes de salvar.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton.filledTonal(
            onPressed: _fechar,
            tooltip: 'Fechar',
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compacto = constraints.maxWidth < 1100;
        final Widget editor = _buildEditorPanel(theme);
        final Widget preview = _buildPreviewPanel(theme);

        if (compacto) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                editor,
                const SizedBox(height: 20),
                preview,
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: 420,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: editor,
              ),
            ),
            VerticalDivider(width: 1, color: theme.colorScheme.outlineVariant),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: preview,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditorPanel(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildSectionCard(
          theme: theme,
          title: 'Tema e densidade visual',
          subtitle: 'Controle a leitura da interface em balcão, notebook e telas maiores.',
          child: Column(
            children: <Widget>[
              _buildDropdown(
                label: 'Tema do sistema',
                value: _temaSelecionado,
                items: const <String>['Claro', 'Escuro', 'Automático'],
                onChanged: _alterarTema,
              ),
              const SizedBox(height: 14),
              _buildDropdown(
                label: 'Densidade visual',
                value: _densidadeSelecionada,
                items: const <String>['Confortável', 'Compacta', 'Expandida'],
                onChanged: _alterarDensidade,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _buildSectionCard(
          theme: theme,
          title: 'Paleta do sistema',
          subtitle: 'As cores selecionadas abaixo são refletidas imediatamente no preview.',
          child: Column(
            children: <Widget>[
              _buildColorSelector('Cor primária', _corPrimaria, _TipoCorSistema.primaria),
              const SizedBox(height: 14),
              _buildColorSelector('Cor secundária', _corSecundaria, _TipoCorSistema.secundaria),
              const SizedBox(height: 14),
              _buildColorSelector('Cor de destaque', _corDestaque, _TipoCorSistema.destaque),
              const SizedBox(height: 14),
              _buildColorSelector('Cor de alerta', _corAlerta, _TipoCorSistema.alerta),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
      items: items
          .map(
            (String item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
    );
  }

  Widget _buildColorSelector(String label, Color color, _TipoCorSistema tipo) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                _hex(color),
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: _coresSugeridas.map((Color opcao) {
              final bool selecionada = opcao.value == color.value;
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _alterarCor(tipo, opcao),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: opcao,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selecionada ? theme.colorScheme.onSurface : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: selecionada
                        ? <BoxShadow>[
                            BoxShadow(
                              color: opcao.withOpacity(0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: selecionada
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildPreviewHero(theme),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double cardWidth = constraints.maxWidth < 900
                ? constraints.maxWidth
                : (constraints.maxWidth - 36) / 3;
            return Wrap(
              spacing: 18,
              runSpacing: 18,
              children: <Widget>[
                SizedBox(width: cardWidth, child: _buildMiniDashboard()),
                SizedBox(width: cardWidth, child: _buildMiniProdutos()),
                SizedBox(width: cardWidth, child: _buildMiniAtendimento()),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _buildTokenPreview(theme),
      ],
    );
  }

  Widget _buildPreviewHero(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            _corPrimaria.withOpacity(0.14),
            _corSecundaria.withOpacity(0.10),
            _corDestaque.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildPill('Experiência visual em tempo real', _corDestaque),
                const SizedBox(height: 12),
                Text(
                  'Veja como o Six vai se comportar antes de salvar',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'As miniaturas usam a paleta selecionada para simular dashboards, listas e telas de atendimento.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          _buildDensityScale(),
        ],
      ),
    );
  }

  Widget _buildDensityScale() {
    final double gap = _densidadeSelecionada == 'Compacta'
        ? 5
        : _densidadeSelecionada == 'Expandida'
            ? 13
            : 9;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _corPrimaria.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _densidadeSelecionada,
            style: TextStyle(
              color: _corPrimaria,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: gap),
          _fakeLine(_corPrimaria, 92),
          SizedBox(height: gap),
          _fakeLine(_corSecundaria, 116),
          SizedBox(height: gap),
          _fakeLine(_corDestaque, 72),
        ],
      ),
    );
  }

  Widget _buildMiniDashboard() {
    return _MiniTelaSistema(
      titulo: 'Dashboard',
      primaria: _corPrimaria,
      secundaria: _corSecundaria,
      destaque: _corDestaque,
      alerta: _corAlerta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _metricCard('Vendas', 'R\$ 8,4k', _corPrimaria)),
              const SizedBox(width: 8),
              Expanded(child: _metricCard('OS abertas', '18', _corAlerta)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              _bar(32, _corPrimaria),
              _bar(54, _corSecundaria),
              _bar(42, _corDestaque),
              _bar(68, _corPrimaria),
              _bar(48, _corSecundaria),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniProdutos() {
    return _MiniTelaSistema(
      titulo: 'Produtos',
      primaria: _corPrimaria,
      secundaria: _corSecundaria,
      destaque: _corDestaque,
      alerta: _corAlerta,
      child: Column(
        children: <Widget>[
          _miniListTile('Tela iPhone 11', 'Estoque 8', _corDestaque),
          const SizedBox(height: 8),
          _miniListTile('Bateria Samsung', 'Estoque baixo', _corAlerta),
          const SizedBox(height: 8),
          _miniListTile('Serviço diagnóstico', 'Ativo', _corSecundaria),
        ],
      ),
    );
  }

  Widget _buildMiniAtendimento() {
    return _MiniTelaSistema(
      titulo: 'Atendimento',
      primaria: _corPrimaria,
      secundaria: _corSecundaria,
      destaque: _corDestaque,
      alerta: _corAlerta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _fakeLine(_corPrimaria, double.infinity)),
              const SizedBox(width: 8),
              _roundIcon(_corDestaque),
            ],
          ),
          const SizedBox(height: 12),
          _step('Recebido', true, _corDestaque),
          _step('Em análise', true, _corPrimaria),
          _step('Aguardando peça', false, _corAlerta),
          const SizedBox(height: 10),
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: _corPrimaria,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'Salvar atendimento',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenPreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Paleta aplicada',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _buildColorToken('Primária', _corPrimaria),
              _buildColorToken('Secundária', _corSecundaria),
              _buildColorToken('Destaque', _corDestaque),
              _buildColorToken('Alerta', _corAlerta),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: <Widget>[
          Text(
            _possuiAlteracoes
                ? 'Você está vendo uma prévia. Salve para aplicar definitivamente.'
                : 'Tudo salvo. Você pode ajustar a paleta a qualquer momento.',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _restaurarPadrao,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Restaurar padrão'),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _salvando ? null : _salvar,
            icon: _salvando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_salvando ? 'Salvando...' : 'Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }

  Widget _buildColorToken(String label, Color color) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(_hex(color), style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _miniListTile(String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        children: <Widget>[
          _roundIcon(color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                Text(subtitle, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIcon(Color color) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.circle, color: color, size: 10),
    );
  }

  Widget _step(String label, bool done, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _bar(double height, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  Widget _fakeLine(Color color, double width) {
    return Container(
      width: width,
      height: 9,
      decoration: BoxDecoration(
        color: color.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  String _hex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}

enum _TipoCorSistema { primaria, secundaria, destaque, alerta }

class _MiniTelaSistema extends StatelessWidget {
  const _MiniTelaSistema({
    required this.titulo,
    required this.primaria,
    required this.secundaria,
    required this.destaque,
    required this.alerta,
    required this.child,
  });

  final String titulo;
  final Color primaria;
  final Color secundaria;
  final Color destaque;
  final Color alerta;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 310,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: primaria.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: <Color>[primaria, secundaria]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: destaque,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}
