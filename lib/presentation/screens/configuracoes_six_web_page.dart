import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/aparencia/aparencia_api_client.dart';
import '../../design_system/helpers/six_theme_resolver.dart';
import '../../domain/models/aparencia_models.dart';
import '../../domain/models/regionalizacao_models.dart';
import '../../domain/services/aparencia/aparencia_service.dart';
import '../../providers/locale_settings_provider.dart';

class ConfiguracoesSixWebPage extends StatefulWidget {
  const ConfiguracoesSixWebPage({
    super.key,
    this.embedded = false,
    this.onBack,
  });

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<ConfiguracoesSixWebPage> createState() =>
      _ConfiguracoesSixWebPageState();
}

enum SecaoConfiguracaoSix {
  geral,
  regionalizacao,
  aparencia,
  comunicacao,
  documentos,
  operacao,
  seguranca,
  preferenciasUsuario,
}

class _ConfiguracoesSixWebPageState extends State<ConfiguracoesSixWebPage> {
  SecaoConfiguracaoSix _secaoAtual = SecaoConfiguracaoSix.geral;
  bool _mostrarResumoLateral = true;
  bool _possuiAlteracoesNaoSalvas = false;
  bool _carregandoAparencia = false;
  bool _localeInicialSincronizado = false;
  late final AparenciaService _aparenciaService;

  // Geral
  final TextEditingController _nomeEmpresaController =
      TextEditingController(text: 'Six Assistência Premium');
  final TextEditingController _nomeFantasiaController =
      TextEditingController(text: 'Six Repair Center');
  final TextEditingController _documentoFiscalController =
      TextEditingController(text: '12.345.678/0001-90');
  final TextEditingController _telefoneController =
      TextEditingController(text: '+55 (47) 99999-8888');
  final TextEditingController _whatsAppController =
      TextEditingController(text: '+55 (47) 99999-7777');
  final TextEditingController _emailController =
      TextEditingController(text: 'contato@sixrepair.com');
  final TextEditingController _siteController =
      TextEditingController(text: 'www.sixrepair.com');
  final TextEditingController _enderecoController =
      TextEditingController(text: 'Av. Central, 1500 - Centro - Itajaí/SC');

  // Regionalização
  String _idiomaSelecionado = 'pt-BR';
  String _paisRegiaoSelecionado = 'Brasil';
  String _fusoSelecionado = 'America/Sao_Paulo';
  String _formatoDataSelecionado = 'dd/MM/yyyy';
  String _formatoHoraSelecionado = '24 horas';
  String _primeiroDiaSemanaSelecionado = 'Segunda-feira';
  String _formatoNumeroSelecionado = '1.234,56';

  // Financeiro / moeda
  String _moedaSelecionada = 'BRL - Real Brasileiro (R\$)';
  String _posicaoSimboloSelecionada = 'Antes do valor';
  String _casasDecimaisSelecionadas = '2';
  String _separadorDecimalSelecionado = 'Vírgula';
  String _separadorMilharSelecionado = 'Ponto';
  bool _permitirMultiplasMoedas = false;
  bool _aplicarArredondamentoFinanceiro = true;

  // Aparência
  String _temaSelecionado = 'Claro';
  String _densidadeSelecionada = 'Confortável';
  Color _corPrimaria = const Color(0xFF1F3C88);
  Color _corSecundaria = const Color(0xFF5E81F4);
  Color _corDestaque = const Color(0xFF0FA958);
  Color _corAlerta = const Color(0xFFF59E0B);

  // Comunicação
  bool _notificarPorEmail = true;
  bool _notificarPorWhatsApp = true;
  bool _notificarPorTelegram = false;
  bool _envioAutomaticoStatus = true;
  bool _envioManualPermitido = true;
  String _canalPreferencialCliente = 'WhatsApp';
  final TextEditingController _assinaturaMensagemController =
      TextEditingController();
  final TextEditingController _mensagemOrdemCriadaController =
      TextEditingController();
  final TextEditingController _mensagemProntoRetiradaController =
      TextEditingController();

  // Documentos
  String _modeloOrcamentoSelecionado = 'Modelo corporativo moderno';
  String _modeloOrdemServicoSelecionado = 'Modelo técnico com checklist';
  String _modeloReciboSelecionado = 'Modelo enxuto com logo';
  bool _exibirLogoNoPdf = true;
  bool _exibirAssinaturaCliente = true;
  bool _exibirQrCode = false;
  String _tamanhoPapelSelecionado = 'A4';
  String _idiomaDocumentoSelecionado = 'Mesmo idioma do sistema';
  String _moedaDocumentoSelecionada = 'Mesma moeda da empresa';
  final TextEditingController _rodapeDocumentoController =
      TextEditingController();
  final TextEditingController _termosCondicoesController =
      TextEditingController();

  // Operação
  bool _controlarEstoque = true;
  bool _exigirClienteNaVenda = false;
  bool _exigirSerialImei = true;
  bool _exigirTecnicoResponsavel = true;
  bool _abrirCaixaObrigatorio = true;
  bool _permitirVendaSemEstoque = false;
  bool _gerarComissaoColaborador = true;
  bool _permitirEdicaoAposFechamento = false;
  bool _descontoManualPermitido = true;
  double _limiteDesconto = 10;

  final List<String> _statusAssistencia = <String>[
    'Recebido',
    'Em análise',
    'Aguardando aprovação',
    'Aguardando peça',
    'Em reparo',
    'Pronto para retirada',
    'Entregue',
  ];

  // Segurança
  bool _mfaHabilitado = false;
  bool _encerrarSessoesInativas = true;
  String _tempoSessaoSelecionado = '8 horas';
  bool _permitirLoginMultiplo = true;
  bool _exigirTrocaSenhaPeriodica = false;

  // Preferências do usuário
  String _paginaInicialSelecionada = 'Painel administrativo';
  bool _receberSomNotificacao = true;
  bool _receberNotificacoesDesktop = true;
  bool _mostrarDicasContextuais = true;
  final List<String> _atalhosFavoritos = <String>[
    'Nova venda',
    'Nova ordem de serviço',
    'Caixa',
    'Clientes',
  ];

  _ConfiguracoesSixL10n get _l10n => _ConfiguracoesSixL10n(_idiomaSelecionado);

  @override
  void initState() {
    super.initState();
    _aparenciaService = AparenciaService(apiClient: HttpAparenciaApiClient());
    _atualizarTextosEditaveisDoIdioma();
    _carregarAparencia();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localeInicialSincronizado) return;

    final locale = context.read<LocaleSettingsProvider>().currentLocale;
    _idiomaSelecionado = _localeParaCodigoSuportado(locale);
    _atualizarTextosEditaveisDoIdioma();
    _localeInicialSincronizado = true;
  }

  @override
  void dispose() {
    _nomeEmpresaController.dispose();
    _nomeFantasiaController.dispose();
    _documentoFiscalController.dispose();
    _telefoneController.dispose();
    _whatsAppController.dispose();
    _emailController.dispose();
    _siteController.dispose();
    _enderecoController.dispose();
    _assinaturaMensagemController.dispose();
    _mensagemOrdemCriadaController.dispose();
    _mensagemProntoRetiradaController.dispose();
    _rodapeDocumentoController.dispose();
    _termosCondicoesController.dispose();
    super.dispose();
  }

  Future<void> _carregarAparencia() async {
    setState(() => _carregandoAparencia = true);
    try {
      final config = await _aparenciaService.buscarAparencia();
      if (!mounted) return;
      setState(() {
        _temaSelecionado = config.tema.label;
        _densidadeSelecionada = SixThemeResolver().densidade.label;
        _corPrimaria = config.paleta.primaria;
        _corSecundaria = config.paleta.secundaria;
        _corDestaque = config.paleta.destaque;
        _corAlerta = config.paleta.alerta;
        SixThemeResolver().atualizarConfiguracao(config);
      });
    } catch (e) {
      debugPrint('Erro ao carregar aparência: $e');
    } finally {
      if (mounted) setState(() => _carregandoAparencia = false);
    }
  }

  void _marcarAlteracao() {
    if (!_possuiAlteracoesNaoSalvas) {
      setState(() => _possuiAlteracoesNaoSalvas = true);
    }
  }

  void _alterarIdioma(String codigoIdioma) {
    setState(() {
      _idiomaSelecionado = codigoIdioma;
      _atualizarTextosEditaveisDoIdioma();
    });
    _marcarAlteracao();
  }

  void _atualizarTextosEditaveisDoIdioma() {
    final l10n = _ConfiguracoesSixL10n(_idiomaSelecionado);
    _assinaturaMensagemController.text = l10n.t('defaultSignature');
    _mensagemOrdemCriadaController.text = l10n.t('defaultOrderCreated');
    _mensagemProntoRetiradaController.text = l10n.t('defaultReadyPickup');
    _rodapeDocumentoController.text = l10n.t('defaultDocumentFooter');
    _termosCondicoesController.text = l10n.t('defaultTerms');
  }

  void _aplicarAparenciaPreview() {
    final resolver = SixThemeResolver();
    final paletaAtual = resolver.paleta;
    resolver.atualizarConfiguracao(
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
      ),
    );
    resolver.atualizarDensidade(
      DensidadeVisualSistema.fromLabel(_densidadeSelecionada),
    );
  }

  Future<void> _salvarConfiguracoes() async {
    setState(() => _carregandoAparencia = true);

    try {
      final localeProvider = context.read<LocaleSettingsProvider>();
      final locale = _mapIdiomaSelecionadoParaLocale(_idiomaSelecionado);

      final configuracaoRegionalizacao = localeProvider.companyConfig.copyWith(
        languageCode: locale.languageCode,
        countryCode: locale.countryCode ?? localeProvider.companyConfig.countryCode,
        formatting: AppRegionalFormatting(
          currencyCode: _mapMoedaSelecionadaParaCurrencyCode(_moedaSelecionada),
          timeZone: _fusoSelecionado,
          dateFormat: _formatoDataSelecionado,
          timeFormat: _formatoHoraSelecionado == '24 horas' ? '24h' : '12h',
          decimalSeparator:
              _separadorDecimalSelecionado == 'Vírgula' ? ',' : '.',
          thousandSeparator: _mapSeparadorMilhar(_separadorMilharSelecionado),
          firstDayOfWeek:
              _primeiroDiaSemanaSelecionado == 'Domingo' ? 'SUNDAY' : 'MONDAY',
          numberPattern:
              _formatoNumeroSelecionado == '1,234.56' ? '#,##0.00' : '#.##0,00',
          decimalPlaces: int.tryParse(_casasDecimaisSelecionadas) ?? 2,
          allowMultipleCurrencies: _permitirMultiplasMoedas,
          applyFinancialRounding: _aplicarArredondamentoFinanceiro,
        ),
      );

      await localeProvider.saveCompanyConfig(configuracaoRegionalizacao);
      await localeProvider.setUserLocale(locale);

      final configuracaoAparencia = ConfiguracaoAparenciaSistema(
        tema: TemaSistema.fromLabel(_temaSelecionado),
        paleta: PaletaSistema(
          primaria: _corPrimaria,
          secundaria: _corSecundaria,
          destaque: _corDestaque,
          alerta: _corAlerta,
          fundo: SixThemeResolver().paleta.fundo,
          superficie: SixThemeResolver().paleta.superficie,
          textoPrimario: SixThemeResolver().paleta.textoPrimario,
          textoSecundario: SixThemeResolver().paleta.textoSecundario,
        ),
      );

      await _aparenciaService.salvarAparencia(configuracaoAparencia);
      SixThemeResolver().atualizarConfiguracao(configuracaoAparencia);
      SixThemeResolver().atualizarDensidade(
        DensidadeVisualSistema.fromLabel(_densidadeSelecionada),
      );

      if (!mounted) return;
      setState(() => _possuiAlteracoesNaoSalvas = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l10n.t('settingsSaved')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_l10n.t('settingsSaveError')}: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _carregandoAparencia = false);
    }
  }

  void _restaurarPadraoDaSecao() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_l10n.t('sectionDefaultsRestored')} "${_tituloSecao(_secaoAtual)}".',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _tituloSecao(SecaoConfiguracaoSix secao) {
    switch (secao) {
      case SecaoConfiguracaoSix.geral:
        return _l10n.t('sectionGeneral');
      case SecaoConfiguracaoSix.regionalizacao:
        return _l10n.t('sectionRegionalization');
      case SecaoConfiguracaoSix.aparencia:
        return _l10n.t('sectionAppearance');
      case SecaoConfiguracaoSix.comunicacao:
        return _l10n.t('sectionCommunication');
      case SecaoConfiguracaoSix.documentos:
        return _l10n.t('sectionDocuments');
      case SecaoConfiguracaoSix.operacao:
        return _l10n.t('sectionOperation');
      case SecaoConfiguracaoSix.seguranca:
        return _l10n.t('sectionSecurity');
      case SecaoConfiguracaoSix.preferenciasUsuario:
        return _l10n.t('sectionUser');
    }
  }

  String _descricaoSecao(SecaoConfiguracaoSix secao) {
    switch (secao) {
      case SecaoConfiguracaoSix.geral:
        return _l10n.t('descGeneral');
      case SecaoConfiguracaoSix.regionalizacao:
        return _l10n.t('descRegionalization');
      case SecaoConfiguracaoSix.aparencia:
        return _l10n.t('descAppearance');
      case SecaoConfiguracaoSix.comunicacao:
        return _l10n.t('descCommunication');
      case SecaoConfiguracaoSix.documentos:
        return _l10n.t('descDocuments');
      case SecaoConfiguracaoSix.operacao:
        return _l10n.t('descOperation');
      case SecaoConfiguracaoSix.seguranca:
        return _l10n.t('descSecurity');
      case SecaoConfiguracaoSix.preferenciasUsuario:
        return _l10n.t('descUser');
    }
  }

  Widget _buildResumoSidebarHeader() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              _l10n.t('configs'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Tooltip(
            message: _l10n.t('hidePanel'),
            child: _roundIconButton(
              icon: Icons.chevron_left_rounded,
              onTap: () => setState(() => _mostrarResumoLateral = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton({required IconData icon, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildResumoSidebar() {
    final theme = Theme.of(context);
    final itens = <({String titulo, String valor, IconData icone})>[
      (
        titulo: _l10n.t('activeLanguage'),
        valor: _l10n.o(_idiomaSelecionado),
        icone: Icons.language_rounded,
      ),
      (
        titulo: _l10n.t('mainCurrency'),
        valor: _mapMoedaSelecionadaParaCurrencyCode(_moedaSelecionada),
        icone: Icons.attach_money_rounded,
      ),
      (
        titulo: _l10n.t('theme'),
        valor: _l10n.o(_temaSelecionado),
        icone: Icons.dark_mode_rounded,
      ),
      (
        titulo: _l10n.t('preferredChannel'),
        valor: _l10n.o(_canalPreferencialCliente),
        icone: Icons.chat_bubble_outline_rounded,
      ),
      (
        titulo: _l10n.t('osModel'),
        valor: _l10n.o(_modeloOrdemServicoSelecionado),
        icone: Icons.description_rounded,
      ),
      (
        titulo: _l10n.t('cashOpening'),
        valor: _abrirCaixaObrigatorio ? _l10n.t('required') : _l10n.t('optional'),
        icone: Icons.point_of_sale_rounded,
      ),
      (
        titulo: _l10n.t('mfa'),
        valor: _mfaHabilitado ? _l10n.t('enabled') : _l10n.t('disabled'),
        icone: Icons.security_rounded,
      ),
    ];

    return Container(
      width: 330,
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildResumoSidebarHeader(),
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  theme.colorScheme.primary.withOpacity(0.08),
                  theme.colorScheme.surfaceContainerHighest.withOpacity(0.70),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _l10n.t('smartPanel'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _l10n.t('smartPanelDescription'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: itens.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = itens[index];
                return _buildResumoCard(
                  icon: item.icone,
                  title: item.titulo,
                  value: item.valor,
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _buildPreviewBrandingCard(),
        ],
      ),
    );
  }

  Widget _buildResumoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
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
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewBrandingCard() {
    final theme = Theme.of(context);
    final nomeMarca = _nomeFantasiaController.text.isEmpty
        ? _l10n.t('yourBrandHere')
        : _nomeFantasiaController.text;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _l10n.t('visualPreview'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: <Color>[
                  _corPrimaria.withOpacity(0.16),
                  _corSecundaria.withOpacity(0.10),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  nomeMarca,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_l10n.t('theme')} ${_l10n.o(_temaSelecionado)} • '
                  '${_l10n.t('currency')} ${_mapMoedaSelecionadaParaCurrencyCode(_moedaSelecionada)} • '
                  '${_l10n.t('language')} ${_l10n.o(_idiomaSelecionado)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _buildColorBadge(_corPrimaria, _l10n.t('primaryColor')),
                    _buildColorBadge(_corSecundaria, _l10n.t('secondaryColor')),
                    _buildColorBadge(_corDestaque, _l10n.t('accentColor')),
                    _buildColorBadge(_corAlerta, _l10n.t('alertColor')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorBadge(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildResumoSidebarCollapsed() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14, right: 12),
      child: Tooltip(
        message: _l10n.t('showPanel'),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _mostrarResumoLateral = true),
          child: Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                Icon(Icons.dashboard_customize_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(height: 10),
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    _l10n.t('summary'),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Icon(Icons.chevron_right_rounded,
                    color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuLateralSecoes() {
    final theme = Theme.of(context);
    final itens = <({SecaoConfiguracaoSix secao, String titulo, IconData icone})>[
      (secao: SecaoConfiguracaoSix.geral, titulo: _l10n.t('sectionGeneral'), icone: Icons.apartment_rounded),
      (secao: SecaoConfiguracaoSix.regionalizacao, titulo: _l10n.t('sectionRegionalization'), icone: Icons.public_rounded),
      (secao: SecaoConfiguracaoSix.aparencia, titulo: _l10n.t('sectionAppearance'), icone: Icons.palette_rounded),
      (secao: SecaoConfiguracaoSix.comunicacao, titulo: _l10n.t('sectionCommunication'), icone: Icons.markunread_outlined),
      (secao: SecaoConfiguracaoSix.documentos, titulo: _l10n.t('sectionDocuments'), icone: Icons.picture_as_pdf_rounded),
      (secao: SecaoConfiguracaoSix.operacao, titulo: _l10n.t('sectionOperation'), icone: Icons.settings_suggest_rounded),
      (secao: SecaoConfiguracaoSix.seguranca, titulo: _l10n.t('sectionSecurity'), icone: Icons.security_rounded),
      (secao: SecaoConfiguracaoSix.preferenciasUsuario, titulo: _l10n.t('sectionUser'), icone: Icons.person_outline_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _l10n.t('sections'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          ...itens.map((item) {
            final selecionado = _secaoAtual == item.secao;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _secaoAtual = item.secao),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: selecionado
                        ? theme.colorScheme.primary.withOpacity(0.10)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selecionado
                          ? theme.colorScheme.primary.withOpacity(0.25)
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: selecionado
                              ? theme.colorScheme.primary.withOpacity(0.12)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.icone, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.titulo,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: selecionado
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String titulo,
    required String descricao,
    required IconData icone,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icone, size: 30, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  titulo,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  descricao,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigCard({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 16),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) {
        setState(() {});
        _marcarAlteracao();
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      onChanged: (novo) {
        onChanged(novo);
        _marcarAlteracao();
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(_l10n.o(item)),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
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
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: (novo) {
              onChanged(novo);
              _marcarAlteracao();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector({
    required String label,
    required Color color,
    required ValueChanged<Color> onColorSelected,
  }) {
    final opcoes = <Color>[
      const Color(0xFF1F3C88),
      const Color(0xFF5E81F4),
      const Color(0xFF0FA958),
      const Color(0xFFF59E0B),
      const Color(0xFF7C3AED),
      const Color(0xFFEF4444),
      const Color(0xFF0EA5E9),
      const Color(0xFF111827),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: opcoes.map((opcao) {
              final selecionado = opcao.value == color.value;
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  onColorSelected(opcao);
                  _marcarAlteracao();
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: opcao,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selecionado ? Colors.black : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: selecionado
                      ? const Icon(Icons.check_rounded, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.drag_indicator_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            _l10n.o(label),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutChip(String label) {
    return Chip(
      label: Text(_l10n.o(label)),
      avatar: const Icon(Icons.flash_on_rounded, size: 18),
      onDeleted: () {
        setState(() => _atalhosFavoritos.remove(label));
        _marcarAlteracao();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

  Widget _buildFloatingActions() {
    final theme = Theme.of(context);

    Widget secondaryAction({
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
    }) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Ink(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.55),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 22),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.30)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.embedded && widget.onBack != null) ...<Widget>[
                secondaryAction(
                  icon: Icons.arrow_back_rounded,
                  tooltip: _l10n.t('back'),
                  onPressed: widget.onBack!,
                ),
                const SizedBox(height: 10),
              ],
              secondaryAction(
                icon: Icons.restart_alt_rounded,
                tooltip: _l10n.t('restoreDefault'),
                onPressed: _restaurarPadraoDaSecao,
              ),
              const SizedBox(height: 14),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _carregandoAparencia ? null : _salvarConfiguracoes,
                  child: Ink(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.save_rounded,
                            color: theme.colorScheme.onPrimary, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _l10n.t('save'),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConteudoSecao() {
    switch (_secaoAtual) {
      case SecaoConfiguracaoSix.geral:
        return _buildSecaoGeral();
      case SecaoConfiguracaoSix.regionalizacao:
        return _buildSecaoRegionalizacao();
      case SecaoConfiguracaoSix.aparencia:
        return _buildSecaoAparencia();
      case SecaoConfiguracaoSix.comunicacao:
        return _buildSecaoComunicacao();
      case SecaoConfiguracaoSix.documentos:
        return _buildSecaoDocumentos();
      case SecaoConfiguracaoSix.operacao:
        return _buildSecaoOperacao();
      case SecaoConfiguracaoSix.seguranca:
        return _buildSecaoSeguranca();
      case SecaoConfiguracaoSix.preferenciasUsuario:
        return _buildSecaoPreferenciasUsuario();
    }
  }

  Widget _buildSecaoGeral() {
    return Column(
      children: <Widget>[
        _buildSectionHeader(
          titulo: _l10n.t('generalTitle'),
          descricao: _descricaoSecao(SecaoConfiguracaoSix.geral),
          icone: Icons.apartment_rounded,
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _l10n.t('businessIdentity'),
          subtitle: _l10n.t('businessIdentitySubtitle'),
          trailing: _buildRequiredBadge(),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              _fieldBox(_buildTextField(label: _l10n.t('companyName'), controller: _nomeEmpresaController)),
              _fieldBox(_buildTextField(label: _l10n.t('tradeName'), controller: _nomeFantasiaController)),
              _fieldBox(_buildTextField(label: _l10n.t('taxDocument'), controller: _documentoFiscalController)),
              _fieldBox(_buildTextField(label: _l10n.t('phone'), controller: _telefoneController, keyboardType: TextInputType.phone)),
              _fieldBox(_buildTextField(label: _l10n.t('whatsapp'), controller: _whatsAppController, keyboardType: TextInputType.phone)),
              _fieldBox(_buildTextField(label: _l10n.t('mainEmail'), controller: _emailController, keyboardType: TextInputType.emailAddress)),
              _fieldBox(_buildTextField(label: _l10n.t('website'), controller: _siteController)),
              SizedBox(width: 656, child: _buildTextField(label: _l10n.t('address'), controller: _enderecoController)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _l10n.t('institutionalBranding'),
          subtitle: _l10n.t('institutionalBrandingSubtitle'),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: _l10n.t('preferTradeName'),
                  subtitle: _l10n.t('preferTradeNameSubtitle'),
                  value: true,
                  onChanged: (_) {},
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: _l10n.t('allowCustomWebCover'),
                  subtitle: _l10n.t('allowCustomWebCoverSubtitle'),
                  value: true,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoRegionalizacao() {
    return Column(
      children: <Widget>[
        _buildSectionHeader(
          titulo: _l10n.t('regionalizationTitle'),
          descricao: _descricaoSecao(SecaoConfiguracaoSix.regionalizacao),
          icone: Icons.public_rounded,
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _l10n.t('languageAndConventions'),
          subtitle: _l10n.t('languageAndConventionsSubtitle'),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              _fieldBox(_buildDropdownField(
                label: _l10n.t('systemLanguage'),
                value: _idiomaSelecionado,
                items: const <String>['pt-BR', 'en-US', 'es-ES'],
                onChanged: (valor) {
                  if (valor == null) return;
                  _alterarIdioma(valor);
                },
              )),
              _fieldBox(_buildDropdownField(
                label: _l10n.t('countryRegion'),
                value: _paisRegiaoSelecionado,
                items: const <String>['Brasil', 'Estados Unidos', 'Espanha'],
                onChanged: (valor) => setState(() => _paisRegiaoSelecionado = valor!),
              )),
              _fieldBox(_buildDropdownField(
                label: _l10n.t('timezone'),
                value: _fusoSelecionado,
                items: const <String>['America/Sao_Paulo', 'UTC', 'America/New_York', 'Europe/Madrid'],
                onChanged: (valor) => setState(() => _fusoSelecionado = valor!),
              )),
              _fieldBox(_buildDropdownField(
                label: _l10n.t('dateFormat'),
                value: _formatoDataSelecionado,
                items: const <String>['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'],
                onChanged: (valor) => setState(() => _formatoDataSelecionado = valor!),
              )),
              _fieldBox(_buildDropdownField(
                label: _l10n.t('timeFormat'),
                value: _formatoHoraSelecionado,
                items: const <String>['24 horas', '12 horas'],
                onChanged: (valor) => setState(() => _formatoHoraSelecionado = valor!),
              )),
              _fieldBox(_buildDropdownField(
                label: _l10n.t('firstDayOfWeek'),
                value: _primeiroDiaSemanaSelecionado,
                items: const <String>['Segunda-feira', 'Domingo'],
                onChanged: (valor) => setState(() => _primeiroDiaSemanaSelecionado = valor!),
              )),
              _fieldBox(_buildDropdownField(
                label: _l10n.t('numberFormat'),
                value: _formatoNumeroSelecionado,
                items: const <String>['1.234,56', '1,234.56'],
                onChanged: (valor) => setState(() => _formatoNumeroSelecionado = valor!),
              )),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _l10n.t('currencyAndFinancialStandard'),
          subtitle: _l10n.t('currencyAndFinancialStandardSubtitle'),
          child: Column(
            children: <Widget>[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  _fieldBox(_buildDropdownField(
                    label: _l10n.t('mainCurrencyField'),
                    value: _moedaSelecionada,
                    items: const <String>[
                      'BRL - Real Brasileiro (R\$)',
                      'USD - US Dollar (\$)',
                      'EUR - Euro (€)',
                    ],
                    onChanged: (valor) => setState(() => _moedaSelecionada = valor!),
                  )),
                  _fieldBox(_buildDropdownField(
                    label: _l10n.t('symbolPosition'),
                    value: _posicaoSimboloSelecionada,
                    items: const <String>['Antes do valor', 'Depois do valor'],
                    onChanged: (valor) => setState(() => _posicaoSimboloSelecionada = valor!),
                  )),
                  _fieldBox(_buildDropdownField(
                    label: _l10n.t('decimalPlaces'),
                    value: _casasDecimaisSelecionadas,
                    items: const <String>['0', '2', '3'],
                    onChanged: (valor) => setState(() => _casasDecimaisSelecionadas = valor!),
                  )),
                  _fieldBox(_buildDropdownField(
                    label: _l10n.t('decimalSeparator'),
                    value: _separadorDecimalSelecionado,
                    items: const <String>['Vírgula', 'Ponto'],
                    onChanged: (valor) => setState(() => _separadorDecimalSelecionado = valor!),
                  )),
                  _fieldBox(_buildDropdownField(
                    label: _l10n.t('thousandSeparator'),
                    value: _separadorMilharSelecionado,
                    items: const <String>['Ponto', 'Vírgula', 'Espaço'],
                    onChanged: (valor) => setState(() => _separadorMilharSelecionado = valor!),
                  )),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(
                    width: 430,
                    child: _buildSwitchTile(
                      title: _l10n.t('allowMultipleCurrencies'),
                      subtitle: _l10n.t('allowMultipleCurrenciesSubtitle'),
                      value: _permitirMultiplasMoedas,
                      onChanged: (valor) => setState(() => _permitirMultiplasMoedas = valor),
                    ),
                  ),
                  SizedBox(
                    width: 430,
                    child: _buildSwitchTile(
                      title: _l10n.t('applyFinancialRounding'),
                      subtitle: _l10n.t('applyFinancialRoundingSubtitle'),
                      value: _aplicarArredondamentoFinanceiro,
                      onChanged: (valor) => setState(() => _aplicarArredondamentoFinanceiro = valor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoAparencia() {
    return Column(
      children: <Widget>[
        _buildSectionHeader(
          titulo: _l10n.t('appearanceTitle'),
          descricao: _descricaoSecao(SecaoConfiguracaoSix.aparencia),
          icone: Icons.palette_rounded,
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _l10n.t('themeAndDensity'),
          subtitle: _l10n.t('themeAndDensitySubtitle'),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              _fieldBox(_buildDropdownField(
                label: _l10n.t('visualTheme'),
                value: _temaSelecionado,
                items: const <String>['Claro', 'Escuro', 'Automático'],
                onChanged: (valor) {
                  setState(() => _temaSelecionado = valor!);
                  _aplicarAparenciaPreview();
                },
              )),
              _fieldBox(_buildDropdownField(
                label: _l10n.t('visualDensity'),
                value: _densidadeSelecionada,
                items: const <String>['Compacta', 'Confortável', 'Expandida'],
                onChanged: (valor) {
                  setState(() => _densidadeSelecionada = valor!);
                  _aplicarAparenciaPreview();
                },
              )),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _l10n.t('brandColors'),
          subtitle: _l10n.t('brandColorsSubtitle'),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(width: 300, child: _buildColorSelector(label: _l10n.t('primaryColor'), color: _corPrimaria, onColorSelected: (cor) => setState(() => _corPrimaria = cor))),
              SizedBox(width: 300, child: _buildColorSelector(label: _l10n.t('secondaryColor'), color: _corSecundaria, onColorSelected: (cor) => setState(() => _corSecundaria = cor))),
              SizedBox(width: 300, child: _buildColorSelector(label: _l10n.t('accentColor'), color: _corDestaque, onColorSelected: (cor) => setState(() => _corDestaque = cor))),
              SizedBox(width: 300, child: _buildColorSelector(label: _l10n.t('alertColor'), color: _corAlerta, onColorSelected: (cor) => setState(() => _corAlerta = cor))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoComunicacao() {
    return Column(
      children: <Widget>[
        _buildSectionHeader(
          titulo: _l10n.t('communicationTitle'),
          descricao: _descricaoSecao(SecaoConfiguracaoSix.comunicacao),
          icone: Icons.markunread_outlined,
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _l10n.t('notificationChannels'),
          subtitle: _l10n.t('notificationChannelsSubtitle'),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              _switchBox(_buildSwitchTile(title: _l10n.t('notifyByEmail'), subtitle: _l10n.t('notifyByEmailSubtitle'), value: _notificarPorEmail, onChanged: (valor) => setState(() => _notificarPorEmail = valor))),
              _switchBox(_buildSwitchTile(title: _l10n.t('notifyByWhatsapp'), subtitle: _l10n.t('notifyByWhatsappSubtitle'), value: _notificarPorWhatsApp, onChanged: (valor) => setState(() => _notificarPorWhatsApp = valor))),
              _switchBox(_buildSwitchTile(title: _l10n.t('notifyByTelegram'), subtitle: _l10n.t('notifyByTelegramSubtitle'), value: _notificarPorTelegram, onChanged: (valor) => setState(() => _notificarPorTelegram = valor))),
              _fieldBox(_buildDropdownField(
                label: _l10n.t('preferredCustomerChannel'),
                value: _canalPreferencialCliente,
                items: const <String>['WhatsApp', 'Email', 'Telegram'],
                onChanged: (valor) => setState(() => _canalPreferencialCliente = valor!),
              )),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _l10n.t('automaticMessages'),
          subtitle: _l10n.t('automaticMessagesSubtitle'),
          child: Column(
            children: <Widget>[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  _switchBox(_buildSwitchTile(title: _l10n.t('automaticStatusSending'), subtitle: _l10n.t('automaticStatusSendingSubtitle'), value: _envioAutomaticoStatus, onChanged: (valor) => setState(() => _envioAutomaticoStatus = valor))),
                  _switchBox(_buildSwitchTile(title: _l10n.t('allowManualSending'), subtitle: _l10n.t('allowManualSendingSubtitle'), value: _envioManualPermitido, onChanged: (valor) => setState(() => _envioManualPermitido = valor))),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(width: 460, child: _buildTextField(label: _l10n.t('messageSignature'), controller: _assinaturaMensagemController, maxLines: 3)),
                  SizedBox(width: 460, child: _buildTextField(label: _l10n.t('orderCreatedMessage'), controller: _mensagemOrdemCriadaController, maxLines: 3)),
                  SizedBox(width: 460, child: _buildTextField(label: _l10n.t('readyPickupMessage'), controller: _mensagemProntoRetiradaController, maxLines: 3)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoDocumentos() {
    return Column(
      children: <Widget>[
        _buildSectionHeader(
          titulo: _l10n.t('documentsTitle'),
          descricao: _descricaoSecao(SecaoConfiguracaoSix.documentos),
          icone: Icons.picture_as_pdf_rounded,
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _l10n.t('documentTemplates'),
          subtitle: _l10n.t('documentTemplatesSubtitle'),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              _fieldBox(_buildDropdownField(label: _l10n.t('quoteModel'), value: _modeloOrcamentoSelecionado, items: const <String>['Modelo corporativo moderno', 'Modelo técnico detalhado', 'Modelo simples'], onChanged: (valor) => setState(() => _modeloOrcamentoSelecionado = valor!))),
              _fieldBox(_buildDropdownField(label: _l10n.t('workOrderModel'), value: _modeloOrdemServicoSelecionado, items: const <String>['Modelo técnico com checklist', 'Modelo enxuto', 'Modelo completo com peças'], onChanged: (valor) => setState(() => _modeloOrdemServicoSelecionado = valor!))),
              _fieldBox(_buildDropdownField(label: _l10n.t('receiptModel'), value: _modeloReciboSelecionado, items: const <String>['Modelo enxuto com logo', 'Modelo fiscal detalhado', 'Modelo recibo simples'], onChanged: (valor) => setState(() => _modeloReciboSelecionado = valor!))),
              _fieldBox(_buildDropdownField(label: _l10n.t('paperSize'), value: _tamanhoPapelSelecionado, items: const <String>['A4', 'Carta', '80mm térmico'], onChanged: (valor) => setState(() => _tamanhoPapelSelecionado = valor!))),
              _fieldBox(_buildDropdownField(label: _l10n.t('documentLanguage'), value: _idiomaDocumentoSelecionado, items: const <String>['Mesmo idioma do sistema', 'Português (Brasil)', 'English (US)', 'Español'], onChanged: (valor) => setState(() => _idiomaDocumentoSelecionado = valor!))),
              _fieldBox(_buildDropdownField(label: _l10n.t('documentCurrency'), value: _moedaDocumentoSelecionada, items: const <String>['Mesma moeda da empresa', 'BRL', 'USD', 'EUR'], onChanged: (valor) => setState(() => _moedaDocumentoSelecionada = valor!))),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _l10n.t('pdfVisualComposition'),
          subtitle: _l10n.t('pdfVisualCompositionSubtitle'),
          child: Column(
            children: <Widget>[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  _switchBox(_buildSwitchTile(title: _l10n.t('showLogoPdf'), subtitle: _l10n.t('showLogoPdfSubtitle'), value: _exibirLogoNoPdf, onChanged: (valor) => setState(() => _exibirLogoNoPdf = valor))),
                  _switchBox(_buildSwitchTile(title: _l10n.t('showCustomerSignature'), subtitle: _l10n.t('showCustomerSignatureSubtitle'), value: _exibirAssinaturaCliente, onChanged: (valor) => setState(() => _exibirAssinaturaCliente = valor))),
                  _switchBox(_buildSwitchTile(title: _l10n.t('showQrCode'), subtitle: _l10n.t('showQrCodeSubtitle'), value: _exibirQrCode, onChanged: (valor) => setState(() => _exibirQrCode = valor))),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(width: 460, child: _buildTextField(label: _l10n.t('defaultFooter'), controller: _rodapeDocumentoController, maxLines: 3)),
                  SizedBox(width: 460, child: _buildTextField(label: _l10n.t('termsAndConditions'), controller: _termosCondicoesController, maxLines: 5)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoOperacao() {
    return Column(
      children: <Widget>[
        _buildSectionHeader(
          titulo: _l10n.t('operationTitle'),
          descricao: _descricaoSecao(SecaoConfiguracaoSix.operacao),
          icone: Icons.settings_suggest_rounded,
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _l10n.t('salesStockCash'),
          subtitle: _l10n.t('salesStockCashSubtitle'),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              _switchBox(_buildSwitchTile(title: _l10n.t('controlStock'), subtitle: _l10n.t('controlStockSubtitle'), value: _controlarEstoque, onChanged: (valor) => setState(() => _controlarEstoque = valor))),
              _switchBox(_buildSwitchTile(title: _l10n.t('requireCustomerSale'), subtitle: _l10n.t('requireCustomerSaleSubtitle'), value: _exigirClienteNaVenda, onChanged: (valor) => setState(() => _exigirClienteNaVenda = valor))),
              _switchBox(_buildSwitchTile(title: _l10n.t('requireSerialImei'), subtitle: _l10n.t('requireSerialImeiSubtitle'), value: _exigirSerialImei, onChanged: (valor) => setState(() => _exigirSerialImei = valor))),
              _switchBox(_buildSwitchTile(title: _l10n.t('requireTechnician'), subtitle: _l10n.t('requireTechnicianSubtitle'), value: _exigirTecnicoResponsavel, onChanged: (valor) => setState(() => _exigirTecnicoResponsavel = valor))),
              _switchBox(_buildSwitchTile(title: _l10n.t('mandatoryCashOpening'), subtitle: _l10n.t('mandatoryCashOpeningSubtitle'), value: _abrirCaixaObrigatorio, onChanged: (valor) => setState(() => _abrirCaixaObrigatorio = valor))),
              _switchBox(_buildSwitchTile(title: _l10n.t('allowSaleWithoutStock'), subtitle: _l10n.t('allowSaleWithoutStockSubtitle'), value: _permitirVendaSemEstoque, onChanged: (valor) => setState(() => _permitirVendaSemEstoque = valor))),
              _switchBox(_buildSwitchTile(title: _l10n.t('generateCommission'), subtitle: _l10n.t('generateCommissionSubtitle'), value: _gerarComissaoColaborador, onChanged: (valor) => setState(() => _gerarComissaoColaborador = valor))),
              _switchBox(_buildSwitchTile(title: _l10n.t('allowEditAfterClosing'), subtitle: _l10n.t('allowEditAfterClosingSubtitle'), value: _permitirEdicaoAposFechamento, onChanged: (valor) => setState(() => _permitirEdicaoAposFechamento = valor))),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _l10n.t('discountAndServiceStatus'),
          subtitle: _l10n.t('discountAndServiceStatusSubtitle'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  _switchBox(_buildSwitchTile(title: _l10n.t('allowManualDiscount'), subtitle: _l10n.t('allowManualDiscountSubtitle'), value: _descontoManualPermitido, onChanged: (valor) => setState(() => _descontoManualPermitido = valor))),
                  SizedBox(
                    width: 320,
                    child: Slider(
                      value: _limiteDesconto,
                      min: 0,
                      max: 50,
                      divisions: 10,
                      label: '${_limiteDesconto.toStringAsFixed(0)}%',
                      onChanged: (valor) {
                        setState(() => _limiteDesconto = valor);
                        _marcarAlteracao();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(_l10n.t('technicalServiceStatuses'), style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _statusAssistencia.map(_buildStatusChip).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoSeguranca() {
    return Column(
      children: <Widget>[
        _buildSectionHeader(
          titulo: _l10n.t('securityTitle'),
          descricao: _descricaoSecao(SecaoConfiguracaoSix.seguranca),
          icone: Icons.security_rounded,
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _l10n.t('accessAndSession'),
          subtitle: _l10n.t('accessAndSessionSubtitle'),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              _switchBox(_buildSwitchTile(title: _l10n.t('enableMfa'), subtitle: _l10n.t('enableMfaSubtitle'), value: _mfaHabilitado, onChanged: (valor) => setState(() => _mfaHabilitado = valor))),
              _switchBox(_buildSwitchTile(title: _l10n.t('closeInactiveSessions'), subtitle: _l10n.t('closeInactiveSessionsSubtitle'), value: _encerrarSessoesInativas, onChanged: (valor) => setState(() => _encerrarSessoesInativas = valor))),
              _switchBox(_buildSwitchTile(title: _l10n.t('allowMultipleLogin'), subtitle: _l10n.t('allowMultipleLoginSubtitle'), value: _permitirLoginMultiplo, onChanged: (valor) => setState(() => _permitirLoginMultiplo = valor))),
              _switchBox(_buildSwitchTile(title: _l10n.t('requirePeriodicPasswordChange'), subtitle: _l10n.t('requirePeriodicPasswordChangeSubtitle'), value: _exigirTrocaSenhaPeriodica, onChanged: (valor) => setState(() => _exigirTrocaSenhaPeriodica = valor))),
              _fieldBox(_buildDropdownField(label: _l10n.t('sessionTime'), value: _tempoSessaoSelecionado, items: const <String>['2 horas', '8 horas', '12 horas', '24 horas'], onChanged: (valor) => setState(() => _tempoSessaoSelecionado = valor!))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoPreferenciasUsuario() {
    return Column(
      children: <Widget>[
        _buildSectionHeader(
          titulo: _l10n.t('userPreferencesTitle'),
          descricao: _descricaoSecao(SecaoConfiguracaoSix.preferenciasUsuario),
          icone: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _l10n.t('personalUsageExperience'),
          subtitle: _l10n.t('personalUsageExperienceSubtitle'),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              _fieldBox(_buildDropdownField(label: _l10n.t('homePage'), value: _paginaInicialSelecionada, items: const <String>['Painel administrativo', 'Vendas', 'Ordem de serviço', 'Agenda financeira'], onChanged: (valor) => setState(() => _paginaInicialSelecionada = valor!))),
              _switchBox(_buildSwitchTile(title: _l10n.t('notificationSound'), subtitle: _l10n.t('notificationSoundSubtitle'), value: _receberSomNotificacao, onChanged: (valor) => setState(() => _receberSomNotificacao = valor))),
              _switchBox(_buildSwitchTile(title: _l10n.t('desktopNotifications'), subtitle: _l10n.t('desktopNotificationsSubtitle'), value: _receberNotificacoesDesktop, onChanged: (valor) => setState(() => _receberNotificacoesDesktop = valor))),
              _switchBox(_buildSwitchTile(title: _l10n.t('contextualTips'), subtitle: _l10n.t('contextualTipsSubtitle'), value: _mostrarDicasContextuais, onChanged: (valor) => setState(() => _mostrarDicasContextuais = valor))),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _l10n.t('favoriteShortcuts'),
          subtitle: _l10n.t('favoriteShortcutsSubtitle'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(spacing: 10, runSpacing: 10, children: _atalhosFavoritos.map(_buildShortcutChip).toList()),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _atalhosFavoritos.add('Relatórios'));
                      _marcarAlteracao();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: Text(_l10n.t('addReports')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _atalhosFavoritos.add('Produtos'));
                      _marcarAlteracao();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: Text(_l10n.t('addProducts')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fieldBox(Widget child) => SizedBox(width: 320, child: child);

  Widget _switchBox(Widget child) => SizedBox(width: 420, child: child);

  Widget _buildRequiredBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
      ),
      child: Text(
        _l10n.t('required'),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildConteudoPrincipal() {
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool layoutEmpilhado = constraints.maxWidth < 1180;
          if (layoutEmpilhado) {
            return Column(
              children: <Widget>[
                _buildMenuLateralSecoes(),
                const SizedBox(height: 20),
                _buildConteudoSecao(),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(width: 300, child: _buildMenuLateralSecoes()),
              const SizedBox(width: 20),
              Expanded(child: _buildConteudoSecao()),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_mostrarResumoLateral) ...<Widget>[
            _buildResumoSidebar(),
            const SizedBox(width: 20),
          ] else ...<Widget>[
            _buildResumoSidebarCollapsed(),
          ],
          Expanded(
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: <Widget>[
                    _buildPageHeader(),
                    if (_carregandoAparencia) ...<Widget>[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(minHeight: 3),
                    ],
                    const SizedBox(height: 18),
                    Expanded(child: _buildConteudoPrincipal()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final contentWithFab = Stack(
      children: <Widget>[
        Positioned.fill(child: bodyContent),
        Positioned(right: 36, bottom: 36, child: _buildFloatingActions()),
      ],
    );

    if (widget.embedded) return contentWithFab;
    return Scaffold(body: SafeArea(child: contentWithFab));
  }

  Widget _buildPageHeader() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.settings_rounded, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _l10n.t('pageTitle'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _l10n.t('pageSubtitle'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _possuiAlteracoesNaoSalvas
                  ? theme.colorScheme.primary.withOpacity(0.10)
                  : Colors.green.withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _possuiAlteracoesNaoSalvas
                    ? theme.colorScheme.primary.withOpacity(0.25)
                    : Colors.green.withOpacity(0.25),
              ),
            ),
            child: Text(
              _possuiAlteracoesNaoSalvas
                  ? _l10n.t('unsavedChanges')
                  : _l10n.t('savedState'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _possuiAlteracoesNaoSalvas
                    ? theme.colorScheme.primary
                    : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Locale _mapIdiomaSelecionadoParaLocale(String idioma) {
    switch (idioma) {
      case 'en-US':
        return const Locale('en', 'US');
      case 'es-ES':
        return const Locale('es', 'ES');
      case 'pt-BR':
      default:
        return const Locale('pt', 'BR');
    }
  }

  String _localeParaCodigoSuportado(Locale locale) {
    if (locale.languageCode == 'en') return 'en-US';
    if (locale.languageCode == 'es') return 'es-ES';
    return 'pt-BR';
  }

  String _mapMoedaSelecionadaParaCurrencyCode(String moedaSelecionada) {
    if (moedaSelecionada.startsWith('USD')) return 'USD';
    if (moedaSelecionada.startsWith('EUR')) return 'EUR';
    return 'BRL';
  }

  String _mapSeparadorMilhar(String valor) {
    switch (valor) {
      case 'Vírgula':
        return ',';
      case 'Espaço':
        return ' ';
      case 'Ponto':
      default:
        return '.';
    }
  }
}

class _ConfiguracoesSixL10n {
  const _ConfiguracoesSixL10n(this.localeCode);

  final String localeCode;

  String get _lang {
    if (localeCode.startsWith('en')) return 'en';
    if (localeCode.startsWith('es')) return 'es';
    return 'pt';
  }

  String t(String key) => _textos[_lang]?[key] ?? _textos['pt']?[key] ?? key;

  String o(String value) => _opcoes[_lang]?[value] ?? _opcoes['pt']?[value] ?? value;

  static const Map<String, Map<String, String>> _textos = <String, Map<String, String>>{
    'pt': <String, String>{
      'pageTitle': 'Configurações Six',
      'pageSubtitle': 'Centralize idioma, região, aparência, documentos, operação e preferências da conta.',
      'unsavedChanges': 'Alterações não salvas',
      'savedState': 'Tudo salvo',
      'configs': 'Configs',
      'hidePanel': 'Ocultar painel',
      'showPanel': 'Mostrar painel',
      'summary': 'Resumo',
      'sections': 'Seções',
      'smartPanel': 'Painel inteligente',
      'smartPanelDescription': 'Visualize rapidamente os principais parâmetros operacionais e de branding antes de salvar.',
      'activeLanguage': 'Idioma ativo',
      'mainCurrency': 'Moeda principal',
      'theme': 'Tema',
      'currency': 'Moeda',
      'language': 'Idioma',
      'preferredChannel': 'Canal preferencial',
      'osModel': 'Modelo OS',
      'cashOpening': 'Abertura de caixa',
      'mfa': 'MFA',
      'required': 'Obrigatório',
      'optional': 'Opcional',
      'enabled': 'Habilitado',
      'disabled': 'Desabilitado',
      'visualPreview': 'Preview visual',
      'yourBrandHere': 'Sua marca aqui',
      'primaryColor': 'Primária',
      'secondaryColor': 'Secundária',
      'accentColor': 'Destaque',
      'alertColor': 'Alerta',
      'back': 'Voltar',
      'restoreDefault': 'Restaurar padrão',
      'save': 'Salvar',
      'settingsSaved': 'Configurações salvas com sucesso.',
      'settingsSaveError': 'Erro ao salvar configurações',
      'sectionDefaultsRestored': 'Os valores padrão da seção foram restaurados',
      'sectionGeneral': 'Geral',
      'sectionRegionalization': 'Regionalização',
      'sectionAppearance': 'Aparência',
      'sectionCommunication': 'Comunicação',
      'sectionDocuments': 'Documentos',
      'sectionOperation': 'Operação',
      'sectionSecurity': 'Segurança',
      'sectionUser': 'Usuário',
      'descGeneral': 'Dados institucionais, identidade do comércio e informações principais para documentos e comunicação.',
      'descRegionalization': 'Idioma, país, moeda, fuso horário, formatos de data e padronização financeira da empresa.',
      'descAppearance': 'Tema, densidade visual, branding do sistema e personalização visual do Six.',
      'descCommunication': 'Mensagens automáticas, canais de notificação e preferências de contato com clientes.',
      'descDocuments': 'Templates, rodapés, termos e componentes visuais de PDFs e comprovantes.',
      'descOperation': 'Regras de venda, assistência técnica, controle operacional e comportamento do fluxo.',
      'descSecurity': 'Sessão, autenticação, acesso, políticas de proteção e gestão de segurança da conta.',
      'descUser': 'Ajustes pessoais do operador para melhorar produtividade e experiência no dia a dia.',
      'generalTitle': 'Configurações institucionais',
      'businessIdentity': 'Identidade do comércio',
      'businessIdentitySubtitle': 'Informações usadas em cabeçalhos de documentos, relatórios, ordens de serviço e comunicações da loja.',
      'companyName': 'Nome da empresa',
      'tradeName': 'Nome fantasia',
      'taxDocument': 'Documento fiscal',
      'phone': 'Telefone',
      'whatsapp': 'WhatsApp',
      'mainEmail': 'Email principal',
      'website': 'Site',
      'address': 'Endereço',
      'institutionalBranding': 'Branding institucional',
      'institutionalBrandingSubtitle': 'Estruture a apresentação da marca para a web, PDFs e comunicações futuras do sistema.',
      'preferTradeName': 'Exibir nome fantasia como principal',
      'preferTradeNameSubtitle': 'Quando ativo, o Six prioriza o nome fantasia em documentos e cabeçalhos.',
      'allowCustomWebCover': 'Permitir capa personalizada na web',
      'allowCustomWebCoverSubtitle': 'Prepara a plataforma para futura imagem institucional na tela de login web.',
      'regionalizationTitle': 'Idioma, região e moeda',
      'languageAndConventions': 'Idioma e convenções regionais',
      'languageAndConventionsSubtitle': 'Defina a experiência local da empresa, incluindo idioma, fuso e padrões de exibição.',
      'systemLanguage': 'Idioma do sistema',
      'countryRegion': 'País / região',
      'timezone': 'Fuso horário',
      'dateFormat': 'Formato de data',
      'timeFormat': 'Formato de hora',
      'firstDayOfWeek': 'Primeiro dia da semana',
      'numberFormat': 'Formato numérico',
      'currencyAndFinancialStandard': 'Moeda e padronização financeira',
      'currencyAndFinancialStandardSubtitle': 'Essas definições influenciam dashboards, vendas, ordem de serviço, orçamentos e documentos.',
      'mainCurrencyField': 'Moeda principal',
      'symbolPosition': 'Posição do símbolo',
      'decimalPlaces': 'Casas decimais',
      'decimalSeparator': 'Separador decimal',
      'thousandSeparator': 'Separador de milhar',
      'allowMultipleCurrencies': 'Permitir múltiplas moedas',
      'allowMultipleCurrenciesSubtitle': 'Mantém a base preparada para cenários internacionais e conversão futura.',
      'applyFinancialRounding': 'Aplicar arredondamento financeiro',
      'applyFinancialRoundingSubtitle': 'Padroniza cálculos e evita divergências de centavos em documentos e totais.',
      'appearanceTitle': 'Aparência e personalização visual',
      'themeAndDensity': 'Tema e densidade',
      'themeAndDensitySubtitle': 'Controle como o Six se apresenta para os usuários da empresa.',
      'visualTheme': 'Tema visual',
      'visualDensity': 'Densidade visual',
      'brandColors': 'Cores da marca',
      'brandColorsSubtitle': 'Ajuste a paleta principal usada em telas, cards e destaques.',
      'communicationTitle': 'Comunicação e notificações',
      'notificationChannels': 'Canais de notificação',
      'notificationChannelsSubtitle': 'Escolha como clientes e usuários serão avisados sobre eventos importantes.',
      'notifyByEmail': 'Notificar por email',
      'notifyByEmailSubtitle': 'Envia mensagens formais e comprovantes para o email do cliente.',
      'notifyByWhatsapp': 'Notificar por WhatsApp',
      'notifyByWhatsappSubtitle': 'Facilita comunicação rápida sobre etapas da assistência técnica.',
      'notifyByTelegram': 'Notificar por Telegram',
      'notifyByTelegramSubtitle': 'Mantém o canal preparado para integrações futuras.',
      'preferredCustomerChannel': 'Canal preferencial do cliente',
      'automaticMessages': 'Mensagens automáticas',
      'automaticMessagesSubtitle': 'Configure mensagens usadas nas jornadas da loja.',
      'automaticStatusSending': 'Envio automático de status',
      'automaticStatusSendingSubtitle': 'Dispara mensagens quando a etapa da ordem de serviço muda.',
      'allowManualSending': 'Permitir envio manual',
      'allowManualSendingSubtitle': 'Permite que operadores reenviem mensagens quando necessário.',
      'messageSignature': 'Assinatura da mensagem',
      'orderCreatedMessage': 'Mensagem de ordem criada',
      'readyPickupMessage': 'Mensagem de pronto para retirada',
      'documentsTitle': 'Documentos e comprovantes',
      'documentTemplates': 'Modelos de documentos',
      'documentTemplatesSubtitle': 'Defina o padrão visual de orçamentos, ordens de serviço, recibos e comprovantes.',
      'quoteModel': 'Modelo de orçamento',
      'workOrderModel': 'Modelo de ordem de serviço',
      'receiptModel': 'Modelo de recibo',
      'paperSize': 'Tamanho do papel',
      'documentLanguage': 'Idioma do documento',
      'documentCurrency': 'Moeda do documento',
      'pdfVisualComposition': 'Composição visual do PDF',
      'pdfVisualCompositionSubtitle': 'Ajustes que impactam o compartilhamento via email, WhatsApp e a apresentação final do documento.',
      'showLogoPdf': 'Exibir logo no PDF',
      'showLogoPdfSubtitle': 'Inclui a identidade da empresa no cabeçalho.',
      'showCustomerSignature': 'Exibir assinatura do cliente',
      'showCustomerSignatureSubtitle': 'Mantém a tela pronta para futuros fluxos de assinatura.',
      'showQrCode': 'Exibir QR Code',
      'showQrCodeSubtitle': 'Pode ser usado para validação, consulta ou link temporário no futuro.',
      'defaultFooter': 'Rodapé padrão',
      'termsAndConditions': 'Termos e condições',
      'operationTitle': 'Regras operacionais do comércio',
      'salesStockCash': 'Venda, estoque e caixa',
      'salesStockCashSubtitle': 'Defina o comportamento operacional padrão do Six no balcão e na rotina do caixa.',
      'controlStock': 'Controlar estoque',
      'controlStockSubtitle': 'Atualiza saldo de produtos e permite relatórios operacionais.',
      'requireCustomerSale': 'Exigir cliente na venda',
      'requireCustomerSaleSubtitle': 'Garante rastreabilidade de compras e histórico por pessoa.',
      'requireSerialImei': 'Exigir serial / IMEI',
      'requireSerialImeiSubtitle': 'Ajuda assistências técnicas a rastrear equipamentos recebidos.',
      'requireTechnician': 'Exigir técnico responsável',
      'requireTechnicianSubtitle': 'Mantém clareza de responsabilidade em cada ordem de serviço.',
      'mandatoryCashOpening': 'Abertura de caixa obrigatória',
      'mandatoryCashOpeningSubtitle': 'Impede operações antes da abertura formal do caixa.',
      'allowSaleWithoutStock': 'Permitir venda sem estoque',
      'allowSaleWithoutStockSubtitle': 'Libera venda mesmo quando o saldo do produto estiver zerado.',
      'generateCommission': 'Gerar comissão de colaborador',
      'generateCommissionSubtitle': 'Permite cálculo futuro de comissões por venda ou serviço.',
      'allowEditAfterClosing': 'Permitir edição após fechamento',
      'allowEditAfterClosingSubtitle': 'Controla alterações depois do fechamento do caixa ou operação.',
      'discountAndServiceStatus': 'Descontos e status da assistência',
      'discountAndServiceStatusSubtitle': 'Configure limites comerciais e etapas operacionais da assistência técnica.',
      'allowManualDiscount': 'Desconto manual permitido',
      'allowManualDiscountSubtitle': 'Permite desconto no balcão conforme limite configurado.',
      'technicalServiceStatuses': 'Status da assistência técnica',
      'securityTitle': 'Segurança e acesso',
      'accessAndSession': 'Acesso e sessão',
      'accessAndSessionSubtitle': 'Prepare políticas de proteção para autenticação e uso da conta.',
      'enableMfa': 'Habilitar MFA',
      'enableMfaSubtitle': 'Adiciona uma camada extra de segurança no login.',
      'closeInactiveSessions': 'Encerrar sessões inativas',
      'closeInactiveSessionsSubtitle': 'Reduz risco de acesso indevido em computadores compartilhados.',
      'allowMultipleLogin': 'Permitir login múltiplo',
      'allowMultipleLoginSubtitle': 'Permite uso simultâneo em mais de um dispositivo.',
      'requirePeriodicPasswordChange': 'Exigir troca periódica de senha',
      'requirePeriodicPasswordChangeSubtitle': 'Prepara o produto para políticas corporativas mais rígidas.',
      'sessionTime': 'Tempo de sessão',
      'userPreferencesTitle': 'Preferências do usuário',
      'personalUsageExperience': 'Experiência pessoal de uso',
      'personalUsageExperienceSubtitle': 'Essas opções ajudam o operador a trabalhar melhor no dia a dia sem misturar com configurações globais.',
      'homePage': 'Página inicial',
      'notificationSound': 'Som de notificação',
      'notificationSoundSubtitle': 'Emite feedback sonoro para eventos importantes.',
      'desktopNotifications': 'Notificações desktop',
      'desktopNotificationsSubtitle': 'Mantém alertas visíveis durante o uso do sistema na web.',
      'contextualTips': 'Mostrar dicas contextuais',
      'contextualTipsSubtitle': 'Ajuda novos operadores durante a curva de adoção.',
      'favoriteShortcuts': 'Atalhos favoritos',
      'favoriteShortcutsSubtitle': 'Deixe acessos rápidos para os fluxos mais usados na operação.',
      'addReports': 'Adicionar Relatórios',
      'addProducts': 'Adicionar Produtos',
      'defaultSignature': 'Equipe Six agradece o seu contato. Qualquer dúvida, estamos à disposição.',
      'defaultOrderCreated': 'Sua ordem de serviço foi criada com sucesso.',
      'defaultReadyPickup': 'Seu equipamento está pronto para retirada.',
      'defaultDocumentFooter': 'Obrigado pela preferência. Este documento foi gerado automaticamente pelo Six.',
      'defaultTerms': 'Após aprovação do orçamento, poderá haver necessidade de peças adicionais conforme análise técnica.',
    },
    'en': <String, String>{
      'pageTitle': 'Six Settings',
      'pageSubtitle': 'Centralize language, region, appearance, documents, operation and account preferences.',
      'unsavedChanges': 'Unsaved changes',
      'savedState': 'All saved',
      'configs': 'Configs',
      'hidePanel': 'Hide panel',
      'showPanel': 'Show panel',
      'summary': 'Summary',
      'sections': 'Sections',
      'smartPanel': 'Smart panel',
      'smartPanelDescription': 'Quickly review the main operation and branding parameters before saving.',
      'activeLanguage': 'Active language',
      'mainCurrency': 'Main currency',
      'theme': 'Theme',
      'currency': 'Currency',
      'language': 'Language',
      'preferredChannel': 'Preferred channel',
      'osModel': 'WO model',
      'cashOpening': 'Cash opening',
      'mfa': 'MFA',
      'required': 'Required',
      'optional': 'Optional',
      'enabled': 'Enabled',
      'disabled': 'Disabled',
      'visualPreview': 'Visual preview',
      'yourBrandHere': 'Your brand here',
      'primaryColor': 'Primary',
      'secondaryColor': 'Secondary',
      'accentColor': 'Accent',
      'alertColor': 'Alert',
      'back': 'Back',
      'restoreDefault': 'Restore default',
      'save': 'Save',
      'settingsSaved': 'Settings saved successfully.',
      'settingsSaveError': 'Error saving settings',
      'sectionDefaultsRestored': 'The default values for the section were restored',
      'sectionGeneral': 'General',
      'sectionRegionalization': 'Regionalization',
      'sectionAppearance': 'Appearance',
      'sectionCommunication': 'Communication',
      'sectionDocuments': 'Documents',
      'sectionOperation': 'Operation',
      'sectionSecurity': 'Security',
      'sectionUser': 'User',
      'descGeneral': 'Company details, business identity and core information for documents and communication.',
      'descRegionalization': 'Language, country, currency, time zone, date formats and financial standards.',
      'descAppearance': 'Theme, visual density, system branding and Six visual customization.',
      'descCommunication': 'Automatic messages, notification channels and customer contact preferences.',
      'descDocuments': 'Templates, footers, terms and visual components for PDFs and receipts.',
      'descOperation': 'Sales rules, technical service rules, operational control and flow behavior.',
      'descSecurity': 'Session, authentication, access, protection policies and account security management.',
      'descUser': 'Personal operator settings to improve productivity and day-to-day experience.',
      'generalTitle': 'Institutional settings',
      'businessIdentity': 'Business identity',
      'businessIdentitySubtitle': 'Information used in document headers, reports, work orders and store communication.',
      'companyName': 'Company name',
      'tradeName': 'Trade name',
      'taxDocument': 'Tax document',
      'phone': 'Phone',
      'whatsapp': 'WhatsApp',
      'mainEmail': 'Main email',
      'website': 'Website',
      'address': 'Address',
      'institutionalBranding': 'Institutional branding',
      'institutionalBrandingSubtitle': 'Structure how the brand appears on the web, PDFs and future system communication.',
      'preferTradeName': 'Show trade name as primary',
      'preferTradeNameSubtitle': 'When enabled, Six prioritizes the trade name in documents and headers.',
      'allowCustomWebCover': 'Allow custom web cover',
      'allowCustomWebCoverSubtitle': 'Prepares the platform for a future institutional image on the web login screen.',
      'regionalizationTitle': 'Language, region and currency',
      'languageAndConventions': 'Language and regional conventions',
      'languageAndConventionsSubtitle': 'Set the company local experience, including language, time zone and display patterns.',
      'systemLanguage': 'System language',
      'countryRegion': 'Country / region',
      'timezone': 'Time zone',
      'dateFormat': 'Date format',
      'timeFormat': 'Time format',
      'firstDayOfWeek': 'First day of week',
      'numberFormat': 'Number format',
      'currencyAndFinancialStandard': 'Currency and financial standardization',
      'currencyAndFinancialStandardSubtitle': 'These settings impact dashboards, sales, work orders, quotes and documents.',
      'mainCurrencyField': 'Main currency',
      'symbolPosition': 'Symbol position',
      'decimalPlaces': 'Decimal places',
      'decimalSeparator': 'Decimal separator',
      'thousandSeparator': 'Thousand separator',
      'allowMultipleCurrencies': 'Allow multiple currencies',
      'allowMultipleCurrenciesSubtitle': 'Keeps the base ready for international scenarios and future conversion.',
      'applyFinancialRounding': 'Apply financial rounding',
      'applyFinancialRoundingSubtitle': 'Standardizes calculations and prevents cent differences in documents and totals.',
      'appearanceTitle': 'Appearance and visual customization',
      'themeAndDensity': 'Theme and density',
      'themeAndDensitySubtitle': 'Control how Six is presented to company users.',
      'visualTheme': 'Visual theme',
      'visualDensity': 'Visual density',
      'brandColors': 'Brand colors',
      'brandColorsSubtitle': 'Adjust the main palette used in screens, cards and highlights.',
      'communicationTitle': 'Communication and notifications',
      'notificationChannels': 'Notification channels',
      'notificationChannelsSubtitle': 'Choose how customers and users are notified about important events.',
      'notifyByEmail': 'Notify by email',
      'notifyByEmailSubtitle': 'Sends formal messages and receipts to the customer email.',
      'notifyByWhatsapp': 'Notify by WhatsApp',
      'notifyByWhatsappSubtitle': 'Makes it easier to communicate technical service steps quickly.',
      'notifyByTelegram': 'Notify by Telegram',
      'notifyByTelegramSubtitle': 'Keeps the channel ready for future integrations.',
      'preferredCustomerChannel': 'Preferred customer channel',
      'automaticMessages': 'Automatic messages',
      'automaticMessagesSubtitle': 'Configure messages used in store journeys.',
      'automaticStatusSending': 'Automatic status sending',
      'automaticStatusSendingSubtitle': 'Sends messages when the work order step changes.',
      'allowManualSending': 'Allow manual sending',
      'allowManualSendingSubtitle': 'Allows operators to resend messages when needed.',
      'messageSignature': 'Message signature',
      'orderCreatedMessage': 'Order created message',
      'readyPickupMessage': 'Ready for pickup message',
      'documentsTitle': 'Documents and receipts',
      'documentTemplates': 'Document templates',
      'documentTemplatesSubtitle': 'Set the visual pattern for quotes, work orders, receipts and vouchers.',
      'quoteModel': 'Quote model',
      'workOrderModel': 'Work order model',
      'receiptModel': 'Receipt model',
      'paperSize': 'Paper size',
      'documentLanguage': 'Document language',
      'documentCurrency': 'Document currency',
      'pdfVisualComposition': 'PDF visual composition',
      'pdfVisualCompositionSubtitle': 'Settings that affect sharing by email, WhatsApp and the final document presentation.',
      'showLogoPdf': 'Show logo in PDF',
      'showLogoPdfSubtitle': 'Includes the company identity in the header.',
      'showCustomerSignature': 'Show customer signature',
      'showCustomerSignatureSubtitle': 'Keeps the screen ready for future signature flows.',
      'showQrCode': 'Show QR Code',
      'showQrCodeSubtitle': 'Can be used for validation, lookup or a temporary link in the future.',
      'defaultFooter': 'Default footer',
      'termsAndConditions': 'Terms and conditions',
      'operationTitle': 'Business operation rules',
      'salesStockCash': 'Sales, stock and cash register',
      'salesStockCashSubtitle': 'Set Six default operational behavior at the counter and in cash register routines.',
      'controlStock': 'Control stock',
      'controlStockSubtitle': 'Updates product balance and enables operational reports.',
      'requireCustomerSale': 'Require customer on sale',
      'requireCustomerSaleSubtitle': 'Ensures purchase traceability and customer history.',
      'requireSerialImei': 'Require serial / IMEI',
      'requireSerialImeiSubtitle': 'Helps repair shops track received devices.',
      'requireTechnician': 'Require responsible technician',
      'requireTechnicianSubtitle': 'Keeps responsibility clear in every work order.',
      'mandatoryCashOpening': 'Mandatory cash opening',
      'mandatoryCashOpeningSubtitle': 'Prevents operations before the formal cash opening.',
      'allowSaleWithoutStock': 'Allow sale without stock',
      'allowSaleWithoutStockSubtitle': 'Allows sales even when the product balance is zero.',
      'generateCommission': 'Generate employee commission',
      'generateCommissionSubtitle': 'Enables future commission calculation per sale or service.',
      'allowEditAfterClosing': 'Allow editing after closing',
      'allowEditAfterClosingSubtitle': 'Controls changes after cash or operation closing.',
      'discountAndServiceStatus': 'Discounts and service statuses',
      'discountAndServiceStatusSubtitle': 'Configure commercial limits and technical service operational steps.',
      'allowManualDiscount': 'Manual discount allowed',
      'allowManualDiscountSubtitle': 'Allows counter discount according to the configured limit.',
      'technicalServiceStatuses': 'Technical service statuses',
      'securityTitle': 'Security and access',
      'accessAndSession': 'Access and session',
      'accessAndSessionSubtitle': 'Prepare protection policies for authentication and account usage.',
      'enableMfa': 'Enable MFA',
      'enableMfaSubtitle': 'Adds an extra security layer to login.',
      'closeInactiveSessions': 'Close inactive sessions',
      'closeInactiveSessionsSubtitle': 'Reduces the risk of unauthorized access on shared computers.',
      'allowMultipleLogin': 'Allow multiple login',
      'allowMultipleLoginSubtitle': 'Allows simultaneous use on more than one device.',
      'requirePeriodicPasswordChange': 'Require periodic password change',
      'requirePeriodicPasswordChangeSubtitle': 'Prepares the product for stricter corporate policies.',
      'sessionTime': 'Session time',
      'userPreferencesTitle': 'User preferences',
      'personalUsageExperience': 'Personal usage experience',
      'personalUsageExperienceSubtitle': 'These options help the operator work better without mixing with global settings.',
      'homePage': 'Home page',
      'notificationSound': 'Notification sound',
      'notificationSoundSubtitle': 'Emits sound feedback for important events.',
      'desktopNotifications': 'Desktop notifications',
      'desktopNotificationsSubtitle': 'Keeps alerts visible while using the system on the web.',
      'contextualTips': 'Show contextual tips',
      'contextualTipsSubtitle': 'Helps new operators during the adoption curve.',
      'favoriteShortcuts': 'Favorite shortcuts',
      'favoriteShortcutsSubtitle': 'Keep quick access to the most used operation flows.',
      'addReports': 'Add Reports',
      'addProducts': 'Add Products',
      'defaultSignature': 'The Six team thanks you for contacting us. If you have any questions, we are available.',
      'defaultOrderCreated': 'Your work order has been created successfully.',
      'defaultReadyPickup': 'Your device is ready for pickup.',
      'defaultDocumentFooter': 'Thank you for your preference. This document was generated automatically by Six.',
      'defaultTerms': 'After quote approval, additional parts may be required according to the technical analysis.',
    },
    'es': <String, String>{
      'pageTitle': 'Configuración Six',
      'pageSubtitle': 'Centralice idioma, región, apariencia, documentos, operación y preferencias de la cuenta.',
      'unsavedChanges': 'Cambios no guardados',
      'savedState': 'Todo guardado',
      'configs': 'Configs',
      'hidePanel': 'Ocultar panel',
      'showPanel': 'Mostrar panel',
      'summary': 'Resumen',
      'sections': 'Secciones',
      'smartPanel': 'Panel inteligente',
      'smartPanelDescription': 'Vea rápidamente los principales parámetros operativos y de marca antes de guardar.',
      'activeLanguage': 'Idioma activo',
      'mainCurrency': 'Moneda principal',
      'theme': 'Tema',
      'currency': 'Moneda',
      'language': 'Idioma',
      'preferredChannel': 'Canal preferido',
      'osModel': 'Modelo OS',
      'cashOpening': 'Apertura de caja',
      'mfa': 'MFA',
      'required': 'Obligatorio',
      'optional': 'Opcional',
      'enabled': 'Habilitado',
      'disabled': 'Deshabilitado',
      'visualPreview': 'Vista previa visual',
      'yourBrandHere': 'Su marca aquí',
      'primaryColor': 'Primario',
      'secondaryColor': 'Secundario',
      'accentColor': 'Destacado',
      'alertColor': 'Alerta',
      'back': 'Volver',
      'restoreDefault': 'Restaurar estándar',
      'save': 'Guardar',
      'settingsSaved': 'Configuración guardada con éxito.',
      'settingsSaveError': 'Error al guardar configuración',
      'sectionDefaultsRestored': 'Los valores predeterminados de la sección fueron restaurados',
      'sectionGeneral': 'General',
      'sectionRegionalization': 'Regionalización',
      'sectionAppearance': 'Apariencia',
      'sectionCommunication': 'Comunicación',
      'sectionDocuments': 'Documentos',
      'sectionOperation': 'Operación',
      'sectionSecurity': 'Seguridad',
      'sectionUser': 'Usuario',
      'descGeneral': 'Datos institucionales, identidad del comercio e información principal para documentos y comunicación.',
      'descRegionalization': 'Idioma, país, moneda, zona horaria, formatos de fecha y estandarización financiera de la empresa.',
      'descAppearance': 'Tema, densidad visual, branding del sistema y personalización visual de Six.',
      'descCommunication': 'Mensajes automáticos, canales de notificación y preferencias de contacto con clientes.',
      'descDocuments': 'Plantillas, pies de página, términos y componentes visuales de PDFs y comprobantes.',
      'descOperation': 'Reglas de venta, asistencia técnica, control operativo y comportamiento del flujo.',
      'descSecurity': 'Sesión, autenticación, acceso, políticas de protección y gestión de seguridad de la cuenta.',
      'descUser': 'Ajustes personales del operador para mejorar productividad y experiencia diaria.',
      'generalTitle': 'Configuración institucional',
      'businessIdentity': 'Identidad del comercio',
      'businessIdentitySubtitle': 'Información usada en encabezados de documentos, informes, órdenes de servicio y comunicaciones de la tienda.',
      'companyName': 'Nombre de la empresa',
      'tradeName': 'Nombre comercial',
      'taxDocument': 'Documento fiscal',
      'phone': 'Teléfono',
      'whatsapp': 'WhatsApp',
      'mainEmail': 'Email principal',
      'website': 'Sitio web',
      'address': 'Dirección',
      'institutionalBranding': 'Branding institucional',
      'institutionalBrandingSubtitle': 'Estructure la presentación de la marca para la web, PDFs y futuras comunicaciones del sistema.',
      'preferTradeName': 'Mostrar nombre comercial como principal',
      'preferTradeNameSubtitle': 'Cuando está activo, Six prioriza el nombre comercial en documentos y encabezados.',
      'allowCustomWebCover': 'Permitir portada personalizada en la web',
      'allowCustomWebCoverSubtitle': 'Prepara la plataforma para una futura imagen institucional en la pantalla de login web.',
      'regionalizationTitle': 'Idioma, región y moneda',
      'languageAndConventions': 'Idioma y convenciones regionales',
      'languageAndConventionsSubtitle': 'Defina la experiencia local de la empresa, incluyendo idioma, zona horaria y patrones de visualización.',
      'systemLanguage': 'Idioma del sistema',
      'countryRegion': 'País / región',
      'timezone': 'Zona horaria',
      'dateFormat': 'Formato de fecha',
      'timeFormat': 'Formato de hora',
      'firstDayOfWeek': 'Primer día de la semana',
      'numberFormat': 'Formato numérico',
      'currencyAndFinancialStandard': 'Moneda y estandarización financiera',
      'currencyAndFinancialStandardSubtitle': 'Estas definiciones influyen en dashboards, ventas, órdenes de servicio, presupuestos y documentos.',
      'mainCurrencyField': 'Moneda principal',
      'symbolPosition': 'Posición del símbolo',
      'decimalPlaces': 'Decimales',
      'decimalSeparator': 'Separador decimal',
      'thousandSeparator': 'Separador de miles',
      'allowMultipleCurrencies': 'Permitir múltiples monedas',
      'allowMultipleCurrenciesSubtitle': 'Mantiene la base preparada para escenarios internacionales y conversión futura.',
      'applyFinancialRounding': 'Aplicar redondeo financiero',
      'applyFinancialRoundingSubtitle': 'Estandariza cálculos y evita diferencias de centavos en documentos y totales.',
      'appearanceTitle': 'Apariencia y personalización visual',
      'themeAndDensity': 'Tema y densidad',
      'themeAndDensitySubtitle': 'Controle cómo Six se presenta a los usuarios de la empresa.',
      'visualTheme': 'Tema visual',
      'visualDensity': 'Densidad visual',
      'brandColors': 'Colores de la marca',
      'brandColorsSubtitle': 'Ajuste la paleta principal usada en pantallas, tarjetas y destaques.',
      'communicationTitle': 'Comunicación y notificaciones',
      'notificationChannels': 'Canales de notificación',
      'notificationChannelsSubtitle': 'Elija cómo clientes y usuarios serán avisados sobre eventos importantes.',
      'notifyByEmail': 'Notificar por email',
      'notifyByEmailSubtitle': 'Envía mensajes formales y comprobantes al email del cliente.',
      'notifyByWhatsapp': 'Notificar por WhatsApp',
      'notifyByWhatsappSubtitle': 'Facilita la comunicación rápida sobre etapas de la asistencia técnica.',
      'notifyByTelegram': 'Notificar por Telegram',
      'notifyByTelegramSubtitle': 'Mantiene el canal preparado para integraciones futuras.',
      'preferredCustomerChannel': 'Canal preferido del cliente',
      'automaticMessages': 'Mensajes automáticos',
      'automaticMessagesSubtitle': 'Configure mensajes usados en las jornadas de la tienda.',
      'automaticStatusSending': 'Envío automático de estado',
      'automaticStatusSendingSubtitle': 'Envía mensajes cuando cambia la etapa de la orden de servicio.',
      'allowManualSending': 'Permitir envío manual',
      'allowManualSendingSubtitle': 'Permite que operadores reenvíen mensajes cuando sea necesario.',
      'messageSignature': 'Firma del mensaje',
      'orderCreatedMessage': 'Mensaje de orden creada',
      'readyPickupMessage': 'Mensaje de listo para retirada',
      'documentsTitle': 'Documentos y comprobantes',
      'documentTemplates': 'Modelos de documentos',
      'documentTemplatesSubtitle': 'Defina el estándar visual de presupuestos, órdenes de servicio, recibos y comprobantes.',
      'quoteModel': 'Modelo de presupuesto',
      'workOrderModel': 'Modelo de orden de servicio',
      'receiptModel': 'Modelo de recibo',
      'paperSize': 'Tamaño del papel',
      'documentLanguage': 'Idioma del documento',
      'documentCurrency': 'Moneda del documento',
      'pdfVisualComposition': 'Composición visual del PDF',
      'pdfVisualCompositionSubtitle': 'Ajustes que impactan el envío por email, WhatsApp y la presentación final del documento.',
      'showLogoPdf': 'Mostrar logo en el PDF',
      'showLogoPdfSubtitle': 'Incluye la identidad de la empresa en el encabezado.',
      'showCustomerSignature': 'Mostrar firma del cliente',
      'showCustomerSignatureSubtitle': 'Mantiene la pantalla lista para futuros flujos de firma.',
      'showQrCode': 'Mostrar QR Code',
      'showQrCodeSubtitle': 'Puede usarse para validación, consulta o enlace temporal en el futuro.',
      'defaultFooter': 'Pie de página estándar',
      'termsAndConditions': 'Términos y condiciones',
      'operationTitle': 'Reglas operativas del comercio',
      'salesStockCash': 'Venta, stock y caja',
      'salesStockCashSubtitle': 'Defina el comportamiento operativo estándar de Six en el mostrador y la rutina de caja.',
      'controlStock': 'Controlar stock',
      'controlStockSubtitle': 'Actualiza saldo de productos y permite informes operativos.',
      'requireCustomerSale': 'Exigir cliente en la venta',
      'requireCustomerSaleSubtitle': 'Garantiza trazabilidad de compras e historial por persona.',
      'requireSerialImei': 'Exigir serial / IMEI',
      'requireSerialImeiSubtitle': 'Ayuda a las asistencias técnicas a rastrear equipos recibidos.',
      'requireTechnician': 'Exigir técnico responsable',
      'requireTechnicianSubtitle': 'Mantiene claridad de responsabilidad en cada orden de servicio.',
      'mandatoryCashOpening': 'Apertura de caja obligatoria',
      'mandatoryCashOpeningSubtitle': 'Impide operaciones antes de la apertura formal de caja.',
      'allowSaleWithoutStock': 'Permitir venta sin stock',
      'allowSaleWithoutStockSubtitle': 'Libera venta aunque el saldo del producto esté en cero.',
      'generateCommission': 'Generar comisión de colaborador',
      'generateCommissionSubtitle': 'Permite cálculo futuro de comisiones por venta o servicio.',
      'allowEditAfterClosing': 'Permitir edición después del cierre',
      'allowEditAfterClosingSubtitle': 'Controla cambios después del cierre de caja u operación.',
      'discountAndServiceStatus': 'Descuentos y estados de asistencia',
      'discountAndServiceStatusSubtitle': 'Configure límites comerciales y etapas operativas de la asistencia técnica.',
      'allowManualDiscount': 'Descuento manual permitido',
      'allowManualDiscountSubtitle': 'Permite descuento en mostrador conforme al límite configurado.',
      'technicalServiceStatuses': 'Estados de asistencia técnica',
      'securityTitle': 'Seguridad y acceso',
      'accessAndSession': 'Acceso y sesión',
      'accessAndSessionSubtitle': 'Prepare políticas de protección para autenticación y uso de la cuenta.',
      'enableMfa': 'Habilitar MFA',
      'enableMfaSubtitle': 'Añade una capa extra de seguridad en el login.',
      'closeInactiveSessions': 'Cerrar sesiones inactivas',
      'closeInactiveSessionsSubtitle': 'Reduce el riesgo de acceso indebido en computadoras compartidas.',
      'allowMultipleLogin': 'Permitir login múltiple',
      'allowMultipleLoginSubtitle': 'Permite uso simultáneo en más de un dispositivo.',
      'requirePeriodicPasswordChange': 'Exigir cambio periódico de contraseña',
      'requirePeriodicPasswordChangeSubtitle': 'Prepara el producto para políticas corporativas más rígidas.',
      'sessionTime': 'Tiempo de sesión',
      'userPreferencesTitle': 'Preferencias del usuario',
      'personalUsageExperience': 'Experiencia personal de uso',
      'personalUsageExperienceSubtitle': 'Estas opciones ayudan al operador a trabajar mejor sin mezclar con configuraciones globales.',
      'homePage': 'Página inicial',
      'notificationSound': 'Sonido de notificación',
      'notificationSoundSubtitle': 'Emite feedback sonoro para eventos importantes.',
      'desktopNotifications': 'Notificaciones desktop',
      'desktopNotificationsSubtitle': 'Mantiene alertas visibles durante el uso del sistema en la web.',
      'contextualTips': 'Mostrar consejos contextuales',
      'contextualTipsSubtitle': 'Ayuda a nuevos operadores durante la curva de adopción.',
      'favoriteShortcuts': 'Atajos favoritos',
      'favoriteShortcutsSubtitle': 'Mantenga accesos rápidos a los flujos más usados en la operación.',
      'addReports': 'Agregar Informes',
      'addProducts': 'Agregar Productos',
      'defaultSignature': 'El equipo Six agradece su contacto. Cualquier duda, estamos a disposición.',
      'defaultOrderCreated': 'Su orden de servicio fue creada con éxito.',
      'defaultReadyPickup': 'Su equipo está listo para retirada.',
      'defaultDocumentFooter': 'Gracias por su preferencia. Este documento fue generado automáticamente por Six.',
      'defaultTerms': 'Después de la aprobación del presupuesto, puede ser necesario agregar piezas adicionales según el análisis técnico.',
    },
  };

  static const Map<String, Map<String, String>> _opcoes = <String, Map<String, String>>{
    'pt': <String, String>{
      'pt-BR': 'Português (Brasil)', 'en-US': 'English (US)', 'es-ES': 'Español',
      'Brasil': 'Brasil', 'Estados Unidos': 'Estados Unidos', 'Espanha': 'Espanha',
      '24 horas': '24 horas', '12 horas': '12 horas', 'Segunda-feira': 'Segunda-feira', 'Domingo': 'Domingo',
      'Antes do valor': 'Antes do valor', 'Depois do valor': 'Depois do valor', 'Vírgula': 'Vírgula', 'Ponto': 'Ponto', 'Espaço': 'Espaço',
      'Claro': 'Claro', 'Escuro': 'Escuro', 'Automático': 'Automático', 'Compacta': 'Compacta', 'Confortável': 'Confortável', 'Expandida': 'Expandida',
      'Email': 'Email', 'WhatsApp': 'WhatsApp', 'Telegram': 'Telegram',
      'Modelo corporativo moderno': 'Modelo corporativo moderno', 'Modelo técnico detalhado': 'Modelo técnico detalhado', 'Modelo simples': 'Modelo simples',
      'Modelo técnico com checklist': 'Modelo técnico com checklist', 'Modelo enxuto': 'Modelo enxuto', 'Modelo completo com peças': 'Modelo completo com peças',
      'Modelo enxuto com logo': 'Modelo enxuto com logo', 'Modelo fiscal detalhado': 'Modelo fiscal detalhado', 'Modelo recibo simples': 'Modelo recibo simples',
      'A4': 'A4', 'Carta': 'Carta', '80mm térmico': '80mm térmico', 'Mesmo idioma do sistema': 'Mesmo idioma do sistema', 'Português (Brasil)': 'Português (Brasil)', 'English (US)': 'English (US)', 'Español': 'Español', 'Mesma moeda da empresa': 'Mesma moeda da empresa',
      'Recebido': 'Recebido', 'Em análise': 'Em análise', 'Aguardando aprovação': 'Aguardando aprovação', 'Aguardando peça': 'Aguardando peça', 'Em reparo': 'Em reparo', 'Pronto para retirada': 'Pronto para retirada', 'Entregue': 'Entregue',
      '2 horas': '2 horas', '8 horas': '8 horas', '12 horas': '12 horas', '24 horas': '24 horas',
      'Painel administrativo': 'Painel administrativo', 'Vendas': 'Vendas', 'Ordem de serviço': 'Ordem de serviço', 'Agenda financeira': 'Agenda financeira', 'Nova venda': 'Nova venda', 'Nova ordem de serviço': 'Nova ordem de serviço', 'Caixa': 'Caixa', 'Clientes': 'Clientes', 'Relatórios': 'Relatórios', 'Produtos': 'Produtos',
    },
    'en': <String, String>{
      'pt-BR': 'Portuguese (Brazil)', 'en-US': 'English (US)', 'es-ES': 'Spanish',
      'Brasil': 'Brazil', 'Estados Unidos': 'United States', 'Espanha': 'Spain',
      '24 horas': '24 hours', '12 horas': '12 hours', 'Segunda-feira': 'Monday', 'Domingo': 'Sunday',
      'Antes do valor': 'Before amount', 'Depois do valor': 'After amount', 'Vírgula': 'Comma', 'Ponto': 'Dot', 'Espaço': 'Space',
      'Claro': 'Light', 'Escuro': 'Dark', 'Automático': 'Automatic', 'Compacta': 'Compact', 'Confortável': 'Comfortable', 'Expandida': 'Expanded',
      'Email': 'Email', 'WhatsApp': 'WhatsApp', 'Telegram': 'Telegram',
      'Modelo corporativo moderno': 'Modern corporate model', 'Modelo técnico detalhado': 'Detailed technical model', 'Modelo simples': 'Simple model',
      'Modelo técnico com checklist': 'Technical model with checklist', 'Modelo enxuto': 'Lean model', 'Modelo completo com peças': 'Complete model with parts',
      'Modelo enxuto com logo': 'Lean model with logo', 'Modelo fiscal detalhado': 'Detailed fiscal model', 'Modelo recibo simples': 'Simple receipt model',
      'A4': 'A4', 'Carta': 'Letter', '80mm térmico': '80mm thermal', 'Mesmo idioma do sistema': 'Same as system language', 'Português (Brasil)': 'Portuguese (Brazil)', 'English (US)': 'English (US)', 'Español': 'Spanish', 'Mesma moeda da empresa': 'Same as company currency',
      'Recebido': 'Received', 'Em análise': 'Under analysis', 'Aguardando aprovação': 'Waiting approval', 'Aguardando peça': 'Waiting for part', 'Em reparo': 'In repair', 'Pronto para retirada': 'Ready for pickup', 'Entregue': 'Delivered',
      '2 horas': '2 hours', '8 horas': '8 hours', '12 horas': '12 hours', '24 horas': '24 hours',
      'Painel administrativo': 'Admin dashboard', 'Vendas': 'Sales', 'Ordem de serviço': 'Work order', 'Agenda financeira': 'Financial agenda', 'Nova venda': 'New sale', 'Nova ordem de serviço': 'New work order', 'Caixa': 'Cash register', 'Clientes': 'Customers', 'Relatórios': 'Reports', 'Produtos': 'Products',
    },
    'es': <String, String>{
      'pt-BR': 'Portugués (Brasil)', 'en-US': 'Inglés (US)', 'es-ES': 'Español',
      'Brasil': 'Brasil', 'Estados Unidos': 'Estados Unidos', 'Espanha': 'España',
      '24 horas': '24 horas', '12 horas': '12 horas', 'Segunda-feira': 'Lunes', 'Domingo': 'Domingo',
      'Antes do valor': 'Antes del valor', 'Depois do valor': 'Después del valor', 'Vírgula': 'Coma', 'Ponto': 'Punto', 'Espaço': 'Espacio',
      'Claro': 'Claro', 'Escuro': 'Oscuro', 'Automático': 'Automático', 'Compacta': 'Compacta', 'Confortável': 'Cómoda', 'Expandida': 'Expandida',
      'Email': 'Email', 'WhatsApp': 'WhatsApp', 'Telegram': 'Telegram',
      'Modelo corporativo moderno': 'Modelo corporativo moderno', 'Modelo técnico detalhado': 'Modelo técnico detallado', 'Modelo simples': 'Modelo simple',
      'Modelo técnico com checklist': 'Modelo técnico con checklist', 'Modelo enxuto': 'Modelo enxuto', 'Modelo completo com peças': 'Modelo completo con piezas',
      'Modelo enxuto com logo': 'Modelo enxuto con logo', 'Modelo fiscal detalhado': 'Modelo fiscal detallado', 'Modelo recibo simples': 'Modelo recibo simple',
      'A4': 'A4', 'Carta': 'Carta', '80mm térmico': '80mm térmico', 'Mesmo idioma do sistema': 'Mismo idioma del sistema', 'Português (Brasil)': 'Portugués (Brasil)', 'English (US)': 'Inglés (US)', 'Español': 'Español', 'Mesma moeda da empresa': 'Misma moneda de la empresa',
      'Recebido': 'Recibido', 'Em análise': 'En análisis', 'Aguardando aprovação': 'Esperando aprobación', 'Aguardando peça': 'Esperando pieza', 'Em reparo': 'En reparación', 'Pronto para retirada': 'Listo para retirada', 'Entregue': 'Entregado',
      '2 horas': '2 horas', '8 horas': '8 horas', '12 horas': '12 horas', '24 horas': '24 horas',
      'Painel administrativo': 'Panel administrativo', 'Vendas': 'Ventas', 'Ordem de serviço': 'Orden de servicio', 'Agenda financeira': 'Agenda financiera', 'Nova venda': 'Nueva venta', 'Nova ordem de serviço': 'Nueva orden de servicio', 'Caixa': 'Caja', 'Clientes': 'Clientes', 'Relatórios': 'Informes', 'Produtos': 'Productos',
    },
  };
}
