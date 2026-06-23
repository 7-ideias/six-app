import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/regionalizacao_models.dart';
import '../../l10n/web_i18n_store.dart';
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
  State<ConfiguracoesSixWebPage> createState() => _ConfiguracoesSixWebPageState();
}

class _ConfiguracoesSixWebPageState extends State<ConfiguracoesSixWebPage> {
  String _idiomaSelecionado = 'pt-BR';
  String _paisRegiaoSelecionado = 'Brasil';
  String _fusoSelecionado = 'America/Sao_Paulo';
  String _formatoDataSelecionado = 'dd/MM/yyyy';
  String _formatoHoraSelecionado = '24 horas';
  String _primeiroDiaSemanaSelecionado = 'Segunda-feira';
  String _formatoNumeroSelecionado = '1.234,56';
  String _moedaSelecionada = 'BRL - Real Brasileiro (R\$)';
  String _posicaoSimboloSelecionada = 'Antes do valor';
  String _casasDecimaisSelecionadas = '2';
  String _separadorDecimalSelecionado = 'Vírgula';
  String _separadorMilharSelecionado = 'Ponto';
  String _temaSelecionado = 'Claro';
  String _canalPreferencialCliente = 'WhatsApp';
  String _paginaInicialSelecionada = 'Painel administrativo';
  bool _permitirMultiplasMoedas = false;
  bool _aplicarArredondamentoFinanceiro = true;
  bool _notificarPorEmail = true;
  bool _notificarPorWhatsApp = true;
  bool _notificarPorTelegram = false;
  bool _exibirLogoNoPdf = true;
  bool _controlarEstoque = true;
  bool _abrirCaixaObrigatorio = true;
  bool _mfaHabilitado = false;
  bool _receberNotificacoesDesktop = true;
  bool _possuiAlteracoesNaoSalvas = false;
  bool _salvando = false;
  bool _baixandoIdioma = false;

  final TextEditingController _nomeEmpresaController = TextEditingController(text: 'Six Assistência Premium');
  final TextEditingController _nomeFantasiaController = TextEditingController(text: 'Six Repair Center');
  final TextEditingController _emailController = TextEditingController(text: 'contato@sixrepair.com');
  final TextEditingController _assinaturaMensagemController = TextEditingController();
  final TextEditingController _mensagemOrdemCriadaController = TextEditingController();
  final TextEditingController _mensagemProntoRetiradaController = TextEditingController();
  final TextEditingController _rodapeDocumentoController = TextEditingController();
  final TextEditingController _termosCondicoesController = TextEditingController();

  _SettingsI18n get _i18n => _SettingsI18n(_idiomaSelecionado);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final locale = context.read<LocaleSettingsProvider>().currentLocale;
      setState(() {
        _idiomaSelecionado = _localeParaCodigo(locale);
        _atualizarTextosEditaveis();
      });
    });
  }

  @override
  void dispose() {
    _nomeEmpresaController.dispose();
    _nomeFantasiaController.dispose();
    _emailController.dispose();
    _assinaturaMensagemController.dispose();
    _mensagemOrdemCriadaController.dispose();
    _mensagemProntoRetiradaController.dispose();
    _rodapeDocumentoController.dispose();
    _termosCondicoesController.dispose();
    super.dispose();
  }

  void _marcarAlteracao() {
    if (!_possuiAlteracoesNaoSalvas) {
      setState(() => _possuiAlteracoesNaoSalvas = true);
    }
  }

  Future<void> _alterarIdioma(String codigoIdioma) async {
    final locale = _mapIdiomaParaLocale(codigoIdioma);

    setState(() {
      _baixandoIdioma = true;
      _idiomaSelecionado = codigoIdioma;
    });

    try {
      await context.read<LocaleSettingsProvider>().setUserLocale(locale);
      if (!mounted) return;
      setState(() {
        _atualizarTextosEditaveis();
        _possuiAlteracoesNaoSalvas = true;
      });
    } finally {
      if (mounted) setState(() => _baixandoIdioma = false);
    }
  }

  void _atualizarTextosEditaveis() {
    _assinaturaMensagemController.text = _i18n.t('defaultSignature');
    _mensagemOrdemCriadaController.text = _i18n.t('defaultOrderCreated');
    _mensagemProntoRetiradaController.text = _i18n.t('defaultReadyPickup');
    _rodapeDocumentoController.text = _i18n.t('defaultDocumentFooter');
    _termosCondicoesController.text = _i18n.t('defaultTerms');
  }

  Future<void> _salvarConfiguracoes() async {
    setState(() => _salvando = true);

    try {
      final provider = context.read<LocaleSettingsProvider>();
      final locale = _mapIdiomaParaLocale(_idiomaSelecionado);
      final config = provider.companyConfig.copyWith(
        languageCode: locale.languageCode,
        countryCode: locale.countryCode ?? provider.companyConfig.countryCode,
        formatting: AppRegionalFormatting(
          currencyCode: _mapMoedaParaCurrencyCode(_moedaSelecionada),
          timeZone: _fusoSelecionado,
          dateFormat: _formatoDataSelecionado,
          timeFormat: _formatoHoraSelecionado == '24 horas' ? '24h' : '12h',
          decimalSeparator: _separadorDecimalSelecionado == 'Vírgula' ? ',' : '.',
          thousandSeparator: _mapSeparadorMilhar(_separadorMilharSelecionado),
          firstDayOfWeek: _primeiroDiaSemanaSelecionado == 'Domingo' ? 'SUNDAY' : 'MONDAY',
          numberPattern: _formatoNumeroSelecionado == '1,234.56' ? '#,##0.00' : '#.##0,00',
          decimalPlaces: int.tryParse(_casasDecimaisSelecionadas) ?? 2,
          allowMultipleCurrencies: _permitirMultiplasMoedas,
          applyFinancialRounding: _aplicarArredondamentoFinanceiro,
        ),
      );

      await provider.saveCompanyConfig(config);
      await provider.setUserLocale(locale);

      if (!mounted) return;
      setState(() => _possuiAlteracoesNaoSalvas = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_i18n.t('settingsSaved')), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_i18n.t('settingsSaveError')}: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocaleSettingsProvider>();
    final carregandoIdioma = _baixandoIdioma || provider.i18nLoading;
    final content = _buildContent(context);

    final body = Stack(
      children: <Widget>[
        Positioned.fill(child: content),
        if (carregandoIdioma) Positioned.fill(child: _buildLoadingOverlay(context)),
        Positioned(right: 32, bottom: 32, child: _buildFloatingActions(context)),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(body: SafeArea(child: body));
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 310, child: _buildResumoLateral(context)),
          const SizedBox(width: 18),
          Expanded(
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildHeader(context),
                    const SizedBox(height: 18),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            _buildRegionalizacaoCard(context),
                            const SizedBox(height: 16),
                            _buildAparenciaCard(context),
                            const SizedBox(height: 16),
                            _buildComunicacaoCard(context),
                            const SizedBox(height: 16),
                            _buildDocumentosCard(context),
                            const SizedBox(height: 16),
                            _buildOperacaoSegurancaCard(context),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(18)),
            child: Icon(Icons.settings_rounded, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(_i18n.t('pageTitle'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
              const SizedBox(height: 4),
              Text(_i18n.t('pageSubtitle'), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ]),
          ),
          _buildEstadoAlteracaoChip(context),
        ],
      ),
    );
  }

  Widget _buildEstadoAlteracaoChip(BuildContext context) {
    final theme = Theme.of(context);
    final pendente = _possuiAlteracoesNaoSalvas;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: pendente ? theme.colorScheme.primary.withOpacity(0.10) : Colors.green.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: pendente ? theme.colorScheme.primary.withOpacity(0.25) : Colors.green.withOpacity(0.25)),
      ),
      child: Text(
        pendente ? _i18n.t('unsavedChanges') : _i18n.t('savedState'),
        style: TextStyle(fontWeight: FontWeight.w800, color: pendente ? theme.colorScheme.primary : Colors.green.shade700),
      ),
    );
  }

  Widget _buildResumoLateral(BuildContext context) {
    final theme = Theme.of(context);
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
          Text(_i18n.t('configs'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
          const SizedBox(height: 10),
          Text(_i18n.t('smartPanelDescription'), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.35)),
          const SizedBox(height: 18),
          _summaryTile(Icons.language_rounded, _i18n.t('activeLanguage'), _i18n.o(_idiomaSelecionado)),
          _summaryTile(Icons.attach_money_rounded, _i18n.t('mainCurrency'), _mapMoedaParaCurrencyCode(_moedaSelecionada)),
          _summaryTile(Icons.dark_mode_rounded, _i18n.t('theme'), _i18n.o(_temaSelecionado)),
          _summaryTile(Icons.chat_bubble_outline_rounded, _i18n.t('preferredChannel'), _i18n.o(_canalPreferencialCliente)),
          _summaryTile(Icons.point_of_sale_rounded, _i18n.t('cashOpening'), _abrirCaixaObrigatorio ? _i18n.t('required') : _i18n.t('optional')),
          _summaryTile(Icons.security_rounded, _i18n.t('mfa'), _mfaHabilitado ? _i18n.t('enabled') : _i18n.t('disabled')),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text(_i18n.t('back')),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(IconData icon, String title, String value) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(children: <Widget>[
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ])),
      ]),
    );
  }

  Widget _buildRegionalizacaoCard(BuildContext context) {
    return _sectionCard(
      icon: Icons.public_rounded,
      title: _i18n.t('regionalizationTitle'),
      subtitle: _i18n.t('languageAndConventionsSubtitle'),
      children: <Widget>[
        _dropdown(_i18n.t('systemLanguage'), _idiomaSelecionado, const <String>['pt-BR', 'en-US', 'es-ES'], (value) {
          if (value != null) _alterarIdioma(value);
        }),
        _dropdown(_i18n.t('countryRegion'), _paisRegiaoSelecionado, const <String>['Brasil', 'Estados Unidos', 'Espanha'], (value) => setState(() => _paisRegiaoSelecionado = value!)),
        _dropdown(_i18n.t('timezone'), _fusoSelecionado, const <String>['America/Sao_Paulo', 'UTC', 'America/New_York', 'Europe/Madrid'], (value) => setState(() => _fusoSelecionado = value!)),
        _dropdown(_i18n.t('dateFormat'), _formatoDataSelecionado, const <String>['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'], (value) => setState(() => _formatoDataSelecionado = value!)),
        _dropdown(_i18n.t('timeFormat'), _formatoHoraSelecionado, const <String>['24 horas', '12 horas'], (value) => setState(() => _formatoHoraSelecionado = value!)),
        _dropdown(_i18n.t('firstDayOfWeek'), _primeiroDiaSemanaSelecionado, const <String>['Segunda-feira', 'Domingo'], (value) => setState(() => _primeiroDiaSemanaSelecionado = value!)),
        _dropdown(_i18n.t('numberFormat'), _formatoNumeroSelecionado, const <String>['1.234,56', '1,234.56'], (value) => setState(() => _formatoNumeroSelecionado = value!)),
        _dropdown(_i18n.t('mainCurrencyField'), _moedaSelecionada, const <String>['BRL - Real Brasileiro (R\$)', 'USD - US Dollar (\$)', 'EUR - Euro (€)'], (value) => setState(() => _moedaSelecionada = value!)),
        _dropdown(_i18n.t('symbolPosition'), _posicaoSimboloSelecionada, const <String>['Antes do valor', 'Depois do valor'], (value) => setState(() => _posicaoSimboloSelecionada = value!)),
        _dropdown(_i18n.t('decimalPlaces'), _casasDecimaisSelecionadas, const <String>['0', '2', '3'], (value) => setState(() => _casasDecimaisSelecionadas = value!)),
        _dropdown(_i18n.t('decimalSeparator'), _separadorDecimalSelecionado, const <String>['Vírgula', 'Ponto'], (value) => setState(() => _separadorDecimalSelecionado = value!)),
        _dropdown(_i18n.t('thousandSeparator'), _separadorMilharSelecionado, const <String>['Ponto', 'Vírgula', 'Espaço'], (value) => setState(() => _separadorMilharSelecionado = value!)),
        _switch(_i18n.t('allowMultipleCurrencies'), _i18n.t('allowMultipleCurrenciesSubtitle'), _permitirMultiplasMoedas, (value) => setState(() => _permitirMultiplasMoedas = value)),
        _switch(_i18n.t('applyFinancialRounding'), _i18n.t('applyFinancialRoundingSubtitle'), _aplicarArredondamentoFinanceiro, (value) => setState(() => _aplicarArredondamentoFinanceiro = value)),
      ],
    );
  }

  Widget _buildAparenciaCard(BuildContext context) {
    return _sectionCard(
      icon: Icons.palette_rounded,
      title: _i18n.t('appearanceTitle'),
      subtitle: _i18n.t('themeAndDensitySubtitle'),
      children: <Widget>[
        _dropdown(_i18n.t('visualTheme'), _temaSelecionado, const <String>['Claro', 'Escuro', 'Automático'], (value) => setState(() => _temaSelecionado = value!)),
        _text(_i18n.t('companyName'), _nomeEmpresaController),
        _text(_i18n.t('tradeName'), _nomeFantasiaController),
        _text(_i18n.t('mainEmail'), _emailController),
      ],
    );
  }

  Widget _buildComunicacaoCard(BuildContext context) {
    return _sectionCard(
      icon: Icons.markunread_outlined,
      title: _i18n.t('communicationTitle'),
      subtitle: _i18n.t('notificationChannelsSubtitle'),
      children: <Widget>[
        _switch(_i18n.t('notifyByEmail'), _i18n.t('notifyByEmailSubtitle'), _notificarPorEmail, (value) => setState(() => _notificarPorEmail = value)),
        _switch(_i18n.t('notifyByWhatsapp'), _i18n.t('notifyByWhatsappSubtitle'), _notificarPorWhatsApp, (value) => setState(() => _notificarPorWhatsApp = value)),
        _switch(_i18n.t('notifyByTelegram'), _i18n.t('notifyByTelegramSubtitle'), _notificarPorTelegram, (value) => setState(() => _notificarPorTelegram = value)),
        _dropdown(_i18n.t('preferredCustomerChannel'), _canalPreferencialCliente, const <String>['WhatsApp', 'Email', 'Telegram'], (value) => setState(() => _canalPreferencialCliente = value!)),
        _text(_i18n.t('messageSignature'), _assinaturaMensagemController, maxLines: 3),
        _text(_i18n.t('orderCreatedMessage'), _mensagemOrdemCriadaController, maxLines: 3),
        _text(_i18n.t('readyPickupMessage'), _mensagemProntoRetiradaController, maxLines: 3),
      ],
    );
  }

  Widget _buildDocumentosCard(BuildContext context) {
    return _sectionCard(
      icon: Icons.picture_as_pdf_rounded,
      title: _i18n.t('documentsTitle'),
      subtitle: _i18n.t('pdfVisualCompositionSubtitle'),
      children: <Widget>[
        _switch(_i18n.t('showLogoPdf'), _i18n.t('showLogoPdfSubtitle'), _exibirLogoNoPdf, (value) => setState(() => _exibirLogoNoPdf = value)),
        _text(_i18n.t('defaultFooter'), _rodapeDocumentoController, maxLines: 3),
        _text(_i18n.t('termsAndConditions'), _termosCondicoesController, maxLines: 4),
      ],
    );
  }

  Widget _buildOperacaoSegurancaCard(BuildContext context) {
    return _sectionCard(
      icon: Icons.settings_suggest_rounded,
      title: _i18n.t('operationTitle'),
      subtitle: _i18n.t('salesStockCashSubtitle'),
      children: <Widget>[
        _switch(_i18n.t('controlStock'), _i18n.t('controlStockSubtitle'), _controlarEstoque, (value) => setState(() => _controlarEstoque = value)),
        _switch(_i18n.t('mandatoryCashOpening'), _i18n.t('mandatoryCashOpeningSubtitle'), _abrirCaixaObrigatorio, (value) => setState(() => _abrirCaixaObrigatorio = value)),
        _switch(_i18n.t('enableMfa'), _i18n.t('enableMfaSubtitle'), _mfaHabilitado, (value) => setState(() => _mfaHabilitado = value)),
        _dropdown(_i18n.t('homePage'), _paginaInicialSelecionada, const <String>['Painel administrativo', 'Vendas', 'Ordem de serviço', 'Agenda financeira'], (value) => setState(() => _paginaInicialSelecionada = value!)),
        _switch(_i18n.t('desktopNotifications'), _i18n.t('desktopNotificationsSubtitle'), _receberNotificacoesDesktop, (value) => setState(() => _receberNotificacoesDesktop = value)),
      ],
    );
  }

  Widget _sectionCard({required IconData icon, required String title, required String subtitle, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.colorScheme.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Row(children: <Widget>[
          Container(width: 48, height: 48, decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: theme.colorScheme.primary)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 18),
        Wrap(spacing: 16, runSpacing: 16, children: children),
      ]),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return SizedBox(
      width: 320,
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
        items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(_i18n.o(item), overflow: TextOverflow.ellipsis))).toList(),
        onChanged: (next) {
          onChanged(next);
          _marcarAlteracao();
        },
      ),
    );
  }

  Widget _text(String label, TextEditingController controller, {int maxLines = 1}) {
    return SizedBox(
      width: maxLines > 1 ? 480 : 320,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: (_) => _marcarAlteracao(),
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }

  Widget _switch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 430,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(18), border: Border.all(color: theme.colorScheme.outlineVariant)),
        child: Row(children: <Widget>[
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ])),
          Switch(value: value, onChanged: (next) { onChanged(next); _marcarAlteracao(); }),
        ]),
      ),
    );
  }

  Widget _buildFloatingActions(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: theme.colorScheme.surface.withOpacity(0.86), borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.colorScheme.outlineVariant)),
          child: FilledButton.icon(
            onPressed: (_salvando || _baixandoIdioma) ? null : _salvarConfiguracoes,
            icon: _salvando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_rounded),
            label: Text(_i18n.t('save')),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surface.withOpacity(0.76),
      child: Center(
        child: Container(
          width: 430,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.24)), boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 28, offset: const Offset(0, 16))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
            Text(_i18n.t('loadingLanguageTitle'), textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(_i18n.t('loadingLanguageMessage'), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4)),
          ]),
        ),
      ),
    );
  }

  Locale _mapIdiomaParaLocale(String idioma) {
    switch (idioma) {
      case 'en-US': return const Locale('en', 'US');
      case 'es-ES': return const Locale('es', 'ES');
      case 'pt-BR':
      default: return const Locale('pt', 'BR');
    }
  }

  String _localeParaCodigo(Locale locale) {
    if (locale.languageCode == 'en') return 'en-US';
    if (locale.languageCode == 'es') return 'es-ES';
    return 'pt-BR';
  }

  String _mapMoedaParaCurrencyCode(String moeda) {
    if (moeda.startsWith('USD')) return 'USD';
    if (moeda.startsWith('EUR')) return 'EUR';
    return 'BRL';
  }

  String _mapSeparadorMilhar(String valor) {
    switch (valor) {
      case 'Vírgula': return ',';
      case 'Espaço': return ' ';
      case 'Ponto':
      default: return '.';
    }
  }
}

class _SettingsI18n {
  const _SettingsI18n(this.localeCode);

  final String localeCode;

  String t(String key) {
    return WebI18nStore.instance.string(localeCode, 'configuracoes.$key') ?? key;
  }

  String o(String value) {
    return WebI18nStore.instance.string(localeCode, 'configuracoes.options.$value') ?? value;
  }
}
