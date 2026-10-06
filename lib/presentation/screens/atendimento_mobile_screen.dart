import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:sixpos/core/services/notificacao_service.dart';
import 'package:sixpos/core/services/perfil_negocio_change_service.dart';
import 'package:sixpos/core/services/perfil_negocio_service.dart';
import 'package:sixpos/core/services/visual_asset_sync_service.dart';
import 'package:sixpos/core/services/visual_asset_manifest_cache_service.dart';
import 'package:sixpos/data/models/atendimento_mobile_assets_model.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/data/models/operational_procedure_flow_models.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_app_bar_profile_action.dart';
import 'package:sixpos/presentation/components/mobile/six_imagem_canetinha.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_reorderable_card.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_rotating_intro_card.dart';
import 'package:sixpos/presentation/components/sixoapp_brand_mark.dart';
import 'package:sixpos/presentation/components/six_cached_network_image.dart';
import 'package:sixpos/presentation/components/six_visual_asset_shimmer.dart';
import 'package:sixpos/presentation/controllers/mobile_card_order_preference_controller.dart';
import 'package:sixpos/presentation/coordinators/operational_procedure_flow_coordinator.dart';
import 'package:sixpos/presentation/screens/devolucoes_produtos_mobile_screen.dart';
import 'package:sixpos/presentation/screens/notificacoes_mobile_screen.dart';
import 'package:sixpos/presentation/screens/opcoes_venda_mobile_screen.dart';
import 'package:sixpos/presentation/screens/operacoes_caixa_mobile_screen.dart';
import 'package:sixpos/presentation/screens/receber_mobile_screen.dart';
import 'package:sixpos/presentation/screens/opcoes_servicos_atendimento_mobile_screen.dart';
import 'package:sixpos/providers/empresa_provider.dart';

import '../components/nav_bar_mobile.dart';

typedef AtendimentoMobileNavigate =
    void Function(BuildContext context, Widget page);

class AtendimentoMobileScreen extends StatefulWidget {
  const AtendimentoMobileScreen({
    super.key,
    @visibleForTesting this.procedureCoordinator,
    @visibleForTesting this.onNavigate,
    @visibleForTesting this.showBottomNavigationBar = true,
  });

  final OperationalProcedureFlowCoordinator? procedureCoordinator;
  final AtendimentoMobileNavigate? onNavigate;
  final bool showBottomNavigationBar;

  @override
  State<AtendimentoMobileScreen> createState() =>
      _AtendimentoMobileScreenState();
}

class _AtendimentoMobileScreenState extends State<AtendimentoMobileScreen> {
  static const String _saleAssetContorno =
      'assets/images/atendimento mobile/acao-nova-venda.webp';
  static const String _saleAssetAcento =
      'assets/images/atendimento mobile/acao-nova-venda-acento.webp';
  static const String _serviceAssetContorno =
      'assets/images/atendimento mobile/acao-novo-servico.webp';
  static const String _serviceAssetAcento =
      'assets/images/atendimento mobile/acao-novo-servico-acento.webp';
  static const String _receiveAssetContorno =
      'assets/images/atendimento mobile/acao-receber.webp';
  static const String _receiveAssetAcento =
      'assets/images/atendimento mobile/acao-receber-acento.webp';
  static const String _cashAssetContorno =
      'assets/images/atendimento mobile/acao-operacoes-caixa.webp';
  static const String _cashAssetAcento =
      'assets/images/atendimento mobile/acao-operacoes-caixa-acento.webp';
  static const String _returnAssetContorno =
      'assets/images/atendimento mobile/acao-devolucoes.webp';
  static const String _returnAssetAcento =
      'assets/images/atendimento mobile/acao-devolucoes-acento.webp';

  late final OperationalProcedureFlowCoordinator _procedureCoordinator;
  late final MobileCardOrderPreferenceController<
    AtendimentoMobileCardPreferencia
  >
  _ordemCardsController;
  final NotificacaoService _notificacoes = NotificacaoService();
  final PerfilNegocioService _perfilNegocioService = PerfilNegocioService();
  final EmpresaProvider _empresaProvider = EmpresaProvider();
  final VisualAssetSyncService _assetSync = VisualAssetSyncService.instance;
  final VisualAssetManifestCacheService _manifestCache =
      VisualAssetManifestCacheService.instance;
  StreamSubscription<void>? _assetSyncSubscription;
  StreamSubscription<String>? _profileSubscription;
  AtendimentoMobileAssetsModel? _businessAssets;
  bool _businessAssetsLoading = false;
  int _businessAssetsLoadGeneration = 0;
  String? _businessAssetsEmpresaId;

  SixMobileColorScheme get _colors => context.sixMobileColors;
  Color get _bg => _colors.background;
  Color get _primary => _colors.primary;
  Color get _secondary => _colors.secondary;
  Color get _accent => _colors.accent;

  @override
  void initState() {
    super.initState();
    _procedureCoordinator =
        widget.procedureCoordinator ?? OperationalProcedureFlowCoordinator();
    _ordemCardsController =
        MobileCardOrderPreferenceController<AtendimentoMobileCardPreferencia>(
            ordemPadrao: AtendimentoMobileCardPreferencia.values,
            selecionarOrdem:
                (preferencias) => preferencias.ordemCardsAtendimentoMobile,
            persistirOrdem:
                (ordem) => UsuarioService().atualizarPreferenciasIndividuais(
                  ordemCardsAtendimentoMobile: ordem
                      .map((item) => item.codigo)
                      .toList(growable: false),
                ),
            nomeDaTela: 'Atendimento Mobile',
          )
          ..addListener(_aoAlterarOrdemDosCards)
          ..inicializar();
    _notificacoes.addListener(_onNotificacoesChanged);
    if (!kIsWeb) {
      _empresaProvider.addListener(_onEmpresaChanged);
      _assetSyncSubscription = _assetSync.changes.listen((_) {
        if (mounted) {
          unawaited(_reloadBusinessAssetsWithShimmer());
        }
      });
      _profileSubscription =
          PerfilNegocioChangeService.instance.changes.listen((String companyId) {
        if (mounted) {
          unawaited(_onBusinessProfileChanged(companyId));
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_inicializarImagensGerenciadas());
        }
      });
    }
  }

  @override
  void dispose() {
    _notificacoes.removeListener(_onNotificacoesChanged);
    if (!kIsWeb) {
      _empresaProvider.removeListener(_onEmpresaChanged);
    }
    ++_businessAssetsLoadGeneration;
    _assetSyncSubscription?.cancel();
    _assetSyncSubscription = null;
    _profileSubscription?.cancel();
    _profileSubscription = null;
    _perfilNegocioService.dispose();
    _ordemCardsController
      ..removeListener(_aoAlterarOrdemDosCards)
      ..dispose();
    super.dispose();
  }

  void _aoAlterarOrdemDosCards() {
    if (mounted) setState(() {});
  }

  Future<void> _inicializarImagensGerenciadas() async {
    final String empresaId = await _perfilNegocioService.empresaAtual();
    await _assetSync.restoreLocalState();

    final String? environment = _assetSync.environment;
    if (environment != null) {
      final Map<String, dynamic>? cached = await _manifestCache.load(
        kind: 'atendimento_mobile',
        companyId: empresaId,
        environment: environment,
      );
      if (cached != null && mounted) {
        try {
          setState(() {
            _businessAssetsEmpresaId = empresaId;
            _businessAssets =
                AtendimentoMobileAssetsModel.fromJson(cached);
          });
        } catch (error) {
          debugPrint(
            '[AtendimentoMobile] manifesto local inválido: $error',
          );
        }
      }
    }

    await _assetSync.initialize();
    // The shared version may already be current while this screen's saved
    // manifest is older. Always reconcile it with the backend on entry.
    if (mounted) {
      await _reloadBusinessAssetsWithShimmer();
    }
  }

  Future<void> _onBusinessProfileChanged(String companyId) async {
    final String current = await _perfilNegocioService.empresaAtual();
    if (!mounted || current != companyId) return;
    await _manifestCache.remove(
      kind: 'atendimento_mobile',
      companyId: companyId,
    );
    await _reloadBusinessAssetsWithShimmer();
  }

  Future<void> _reloadBusinessAssetsWithShimmer() async {
    if (!mounted || kIsWeb) return;
    ++_businessAssetsLoadGeneration;
    setState(() {
      _businessAssets = null;
      _businessAssetsEmpresaId = null;
      _businessAssetsLoading = true;
    });
    await _carregarImagensDoPerfil();
  }

  Future<void> _carregarImagensDoPerfil() async {
    final int generation = ++_businessAssetsLoadGeneration;
    try {
      final String empresaId = await _perfilNegocioService.empresaAtual();
      final AtendimentoMobileAssetsModel resolved = await _perfilNegocioService
          .atendimentoMobileAssets(empresaId);
      if (!mounted || generation != _businessAssetsLoadGeneration) return;

      final int fallbacks =
          resolved.assets.where((item) => item.imagemFallback).length;
      debugPrint(
        '[AtendimentoMobile] Assets backend empresa=$empresaId '
        'segmento=${resolved.perfilNegocio.perfil.segmentoPrincipal} '
        'subsegmento=${resolved.perfilNegocio.perfil.subsegmento} '
        'fallbacks=$fallbacks/${resolved.assets.length}',
      );

      final String environment = _assetSync.environment ?? 'LIVE';
      final String version = _assetSync.version ?? '000000000000';
      debugPrint('[AtendimentoMobile] ambiente=$environment versão=$version');
      for (final item in resolved.assets) {
        debugPrint('[AtendimentoMobile] slot=${item.slot} id=${item.id} '
            'fallback=${item.imagemFallback}');
      }
      // Show the selected manifest immediately. Downloading other cards for
      // offline use must not delay the newly published image.
      setState(() {
        _businessAssetsEmpresaId = empresaId;
        _businessAssets = resolved;
        _businessAssetsLoading = false;
      });
      await _manifestCache.prefetchAndSave(
        kind: 'atendimento_mobile',
        companyId: empresaId,
        environment: environment,
        assetsVersion: version,
        payload: resolved.toJson(),
        imageUrls: resolved.assets.map(
          (AtendimentoMobileAssetModel item) => item.imagemUrl,
        ),
      );
    } catch (error) {
      if (!mounted || generation != _businessAssetsLoadGeneration) return;
      debugPrint(
        '[AtendimentoMobile] Falha ao carregar assets do backend: $error',
      );
      if (_businessAssets != null) return;
      setState(() {
        _businessAssets = null;
        _businessAssetsEmpresaId = null;
        _businessAssetsLoading = false;
      });
    }
  }

  void _onEmpresaChanged() {
    if (!mounted || kIsWeb) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_reloadBusinessAssetsWithShimmer());
      }
    });
  }

  AtendimentoMobileAssetModel? _businessAsset(AtendimentoMobileAssetSlot slot) {
    if (kIsWeb) return null;
    return _businessAssets?.asset(slot);
  }

  String? _businessImageUrl(AtendimentoMobileAssetSlot slot) =>
      _businessAsset(slot)?.imagemUrl;

  bool _businessImageFullCard(AtendimentoMobileAssetSlot slot) =>
      _businessAsset(slot)?.modoExibicao ==
      AtendimentoMobileAssetDisplayMode.fullCard;

  String _txt(String key, String fallback) =>
      context.t(key, fallback: fallback);

  void _onNotificacoesChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SixMobilePageShell(
      title: _txt('atendimento.mobile.title', 'Atendimento'),
      backgroundColor: _bg,
      primaryColor: _primary,
      secondaryColor: _secondary,
      accentColor: _accent,
      automaticallyImplyLeading: false,
      leading: SixMobileAppBarProfileAction(),
      actions: <Widget>[
        IconButton(
          tooltip: _txt(
            'gestao.settings.item.notifications.title',
            'Notificações',
          ),
          icon: _notificationIcon(),
          onPressed: () => _go(NotificacoesMobileScreen()),
        ),
      ],
      bodyBuilder: _buildContent,
      bottomNavigationBar:
          kIsWeb || !widget.showBottomNavigationBar
              ? null
              : NavBarMobile(initialIndex: 2),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double textScale = MediaQuery.textScalerOf(context).scale(1);
          final _AtendimentoLayoutSizing sizing =
              _AtendimentoLayoutSizing.resolve(
                viewportHeight: constraints.maxHeight,
                contentWidth: constraints.maxWidth - 32,
                topInset: topInset,
                textScale: textScale,
              );
          final List<_PrimaryActionData> actions = _orderedActions();

          return ListView(
            controller: scrollController,
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 24),
            children: <Widget>[
              SixStaggeredEntry(
                delay: Duration(milliseconds: 40),
                child: SixMobileRotatingIntroCard(
                  title: _txt(
                    'atendimento.mobile.introTitle',
                    'Atendimento ao Cliente',
                  ),
                  subtitles: <String>[
                    _txt(
                      'atendimento.mobile.introLineSales',
                      'vender, receber, consultar',
                    ),
                    _txt(
                      'atendimento.mobile.introLineReturns',
                      'devoluções de produtos',
                    ),
                    _txt(
                      'atendimento.mobile.introLineServices',
                      'serviços, orçamentos etc',
                    ),
                  ],
                  markChild: const SixoAppBrandMark(size: 34),
                ),
              ),
              SizedBox(height: 16),
              if (_businessAssetsLoading) ...<Widget>[
                _AtendimentoActionsShimmerRow(
                  itemCount: 2,
                  prominence: _AtendimentoActionProminence.primary,
                  heightBoost: sizing.primaryRowExtraHeight,
                ),
                const SizedBox(height: 12),
                _AtendimentoActionsShimmerRow(
                  itemCount: 3,
                  prominence: _AtendimentoActionProminence.compact,
                  heightBoost: sizing.compactRowExtraHeight,
                ),
              ] else ...<Widget>[
                SixStaggeredEntry(
                  delay: Duration(milliseconds: 95),
                  child: _AtendimentoActionsRow(
                    actions: actions.take(2).toList(growable: false),
                    prominence: _AtendimentoActionProminence.primary,
                    heightBoost: sizing.primaryRowExtraHeight,
                    onReorder: _ordemCardsController.reordenar,
                  ),
                ),
                const SizedBox(height: 12),
                SixStaggeredEntry(
                  delay: Duration(milliseconds: 130),
                  child: _AtendimentoActionsRow(
                    actions: actions.skip(2).toList(growable: false),
                    prominence: _AtendimentoActionProminence.compact,
                    heightBoost: sizing.compactRowExtraHeight,
                    onReorder: _ordemCardsController.reordenar,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _notificationIcon() {
    final int naoLidas = _notificacoes.naoLidas;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(
          naoLidas > 0
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
        ),
        if (naoLidas > 0)
          Positioned(
            right: -6,
            top: -6,
            child: SixPulsingBadge(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: SixMobilePalette.notificationBadge,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: SixMobilePalette.onPrimary,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  naoLidas > 9 ? '+9' : naoLidas.toString(),
                  style: TextStyle(
                    color: SixMobilePalette.onPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<_PrimaryActionData> _orderedActions() {
    final _AtendimentoVisualTokens visual = _AtendimentoVisualTokens.resolve(
      context,
    );

    final Map<AtendimentoMobileCardPreferencia, _PrimaryActionData> actions =
        <AtendimentoMobileCardPreferencia, _PrimaryActionData>{
          AtendimentoMobileCardPreferencia.novaVenda: _PrimaryActionData(
            preferencia: AtendimentoMobileCardPreferencia.novaVenda,
            id: 'new-sale',
            title: _txt('atendimento.mobile.newSaleTitle', 'Vendas'),
            assetContorno: _saleAssetContorno,
            assetAcento: _saleAssetAcento,
            contextualImageUrl: _businessImageUrl(
              AtendimentoMobileAssetSlot.vendas,
            ),
            contextualImageFullCard: _businessImageFullCard(
              AtendimentoMobileAssetSlot.vendas,
            ),
            accentColor: visual.saleAccent,
            brandStart: SixMobilePalette.brandCyan,
            brandEnd: SixMobilePalette.brandBlue,
            onTap: _openSalesMenu,
            enabled: true,
            statusLabel: null,
          ),
          AtendimentoMobileCardPreferencia.novoServico: _PrimaryActionData(
            preferencia: AtendimentoMobileCardPreferencia.novoServico,
            id: 'new-service',
            title: _txt('atendimento.mobile.newServiceTitle', 'Serviços'),
            assetContorno: _serviceAssetContorno,
            assetAcento: _serviceAssetAcento,
            contextualImageUrl: _businessImageUrl(
              AtendimentoMobileAssetSlot.servicos,
            ),
            contextualImageFullCard: _businessImageFullCard(
              AtendimentoMobileAssetSlot.servicos,
            ),
            accentColor: visual.serviceAccent,
            brandStart: SixMobilePalette.brandBlue,
            brandEnd: SixMobilePalette.brandViolet,
            onTap: _openServicesMenu,
            enabled: true,
            statusLabel: null,
          ),
          AtendimentoMobileCardPreferencia.receber: _PrimaryActionData(
            preferencia: AtendimentoMobileCardPreferencia.receber,
            id: 'receive',
            title: _txt('atendimento.mobile.receiveTitle', 'Receber'),
            assetContorno: _receiveAssetContorno,
            assetAcento: _receiveAssetAcento,
            contextualImageUrl: _businessImageUrl(
              AtendimentoMobileAssetSlot.receber,
            ),
            contextualImageFullCard: _businessImageFullCard(
              AtendimentoMobileAssetSlot.receber,
            ),
            accentColor: visual.receiveAccent,
            brandStart: SixMobilePalette.brandCyan,
            brandEnd: SixMobilePalette.brandBlue,
            onTap: () => _go(ReceberMobileScreen()),
            enabled: true,
            statusLabel: null,
          ),
          AtendimentoMobileCardPreferencia.operacoesCaixa: _PrimaryActionData(
            preferencia: AtendimentoMobileCardPreferencia.operacoesCaixa,
            id: 'cash',
            title: _txt('atendimento.mobile.cashOperationsTitle', 'Caixa'),
            assetContorno: _cashAssetContorno,
            assetAcento: _cashAssetAcento,
            contextualImageUrl: _businessImageUrl(
              AtendimentoMobileAssetSlot.operacoesCaixa,
            ),
            contextualImageFullCard: _businessImageFullCard(
              AtendimentoMobileAssetSlot.operacoesCaixa,
            ),
            accentColor: visual.cashAccent,
            brandStart: SixMobilePalette.brandBlue,
            brandEnd: visual.cashGradientEnd,
            onTap: _openCashOperations,
            enabled: true,
            statusLabel: null,
          ),
          AtendimentoMobileCardPreferencia.devolucao: _PrimaryActionData(
            preferencia: AtendimentoMobileCardPreferencia.devolucao,
            id: 'return',
            title: _txt('operacao.mobile.returnTitle', 'Devoluções e Trocas'),
            assetContorno: _returnAssetContorno,
            assetAcento: _returnAssetAcento,
            contextualImageUrl: _businessImageUrl(
              AtendimentoMobileAssetSlot.devolucao,
            ),
            contextualImageFullCard: _businessImageFullCard(
              AtendimentoMobileAssetSlot.devolucao,
            ),
            accentColor: visual.returnAccent,
            brandStart: visual.returnAccent,
            brandEnd: visual.returnGradientEnd,
            onTap: () => _go(DevolucoesProdutosMobileScreen()),
            enabled: true,
            statusLabel: null,
          ),
        };

    return _ordemCardsController.ordem
        .map((preferencia) => actions[preferencia]!)
        .toList(growable: false);
  }

  void _openSalesMenu() {
    _go(OpcoesVendaMobileScreen(procedureCoordinator: _procedureCoordinator));
  }

  void _openServicesMenu() {
    _go(
      OpcoesServicosAtendimentoMobileScreen(
        procedureCoordinator: _procedureCoordinator,
      ),
    );
  }

  Future<void> _openCashOperations() async {
    final ProcedureFlowResult result = await _procedureCoordinator.execute(
      context: context,
      operationPoint: ProcedureOperationPoint.cashRegisterStartBefore,
    );
    if (!mounted || !result.shouldContinue) return;
    _go(OperacoesCaixaMobileScreen());
  }

  void _go(Widget page) {
    final AtendimentoMobileNavigate? navigate = widget.onNavigate;
    if (navigate != null) {
      navigate(context, page);
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _AtendimentoVisualTokens {
  const _AtendimentoVisualTokens({
    required this.saleAccent,
    required this.serviceAccent,
    required this.receiveAccent,
    required this.cashAccent,
    required this.returnAccent,
    required this.cashGradientEnd,
    required this.returnGradientEnd,
  });

  final Color saleAccent;
  final Color serviceAccent;
  final Color receiveAccent;
  final Color cashAccent;
  final Color returnAccent;
  final Color cashGradientEnd;
  final Color returnGradientEnd;

  LinearGradient get heroGradient => const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[
      SixMobilePalette.brandCyan,
      SixMobilePalette.brandBlue,
      SixMobilePalette.brandViolet,
    ],
  );

  static _AtendimentoVisualTokens resolve(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return _AtendimentoVisualTokens(
      saleAccent:
          isDark ? SixMobilePalette.brandCyan : SixMobilePalette.brandBlue,
      serviceAccent:
          isDark
              ? Color.lerp(
                SixMobilePalette.brandViolet,
                colors.titleText,
                0.36,
              )!
              : SixMobilePalette.brandViolet,
      receiveAccent:
          isDark
              ? SixMobilePalette.brandCyan
              : Color.lerp(
                SixMobilePalette.brandCyan,
                SixMobilePalette.brandNavyDeep,
                0.56,
              )!,
      cashAccent: isDark ? colors.accent : SixMobilePalette.brandBlue,
      returnAccent: colors.error,
      cashGradientEnd: isDark ? colors.accent : SixMobilePalette.brandCyan,
      returnGradientEnd:
          Color.lerp(colors.error, colors.titleText, isDark ? 0.18 : 0.06)!,
    );
  }
}

enum _AtendimentoActionProminence { primary, compact }

class _AtendimentoLayoutSizing {
  const _AtendimentoLayoutSizing({
    required this.primaryRowExtraHeight,
    required this.compactRowExtraHeight,
  });

  final double primaryRowExtraHeight;
  final double compactRowExtraHeight;

  static _AtendimentoLayoutSizing resolve({
    required double viewportHeight,
    required double contentWidth,
    required double topInset,
    required double textScale,
  }) {
    if (!viewportHeight.isFinite) {
      return const _AtendimentoLayoutSizing(
        primaryRowExtraHeight: 0,
        compactRowExtraHeight: 0,
      );
    }

    final bool compactHero = contentWidth < 350 || textScale >= 1.2;
    final double scaleExtra = (textScale - 1).clamp(0.0, 0.8).toDouble();
    final double heroHeight = compactHero ? 142 : 154;
    final double primaryHeight = 190 + (scaleExtra * 82);
    final double compactHeight = 146 + (scaleExtra * 58);
    final double verticalPadding = topInset + 10 + 24;
    const double verticalGaps = 16 + 12;
    final double baseContentHeight =
        heroHeight + primaryHeight + compactHeight + verticalGaps;
    final double availableHeight = viewportHeight - verticalPadding;
    final double extraHeight =
        (availableHeight - baseContentHeight)
            .clamp(0.0, double.infinity)
            .toDouble();

    return _AtendimentoLayoutSizing(
      primaryRowExtraHeight: extraHeight * 0.54,
      compactRowExtraHeight: extraHeight * 0.46,
    );
  }
}

class _AtendimentoActionsShimmerRow extends StatelessWidget {
  const _AtendimentoActionsShimmerRow({
    required this.itemCount,
    required this.prominence,
    this.heightBoost = 0,
  });

  final int itemCount;
  final _AtendimentoActionProminence prominence;
  final double heightBoost;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double textScale = MediaQuery.textScalerOf(context).scale(1);
        final double gap =
            prominence == _AtendimentoActionProminence.primary ? 12 : 8;
        final double scaleExtra =
            (textScale - 1).clamp(0.0, 0.8).toDouble();
        final double baseHeight =
            prominence == _AtendimentoActionProminence.primary
                ? 190 + (scaleExtra * 82)
                : 146 + (scaleExtra * 58);
        final double cardHeight = baseHeight + heightBoost;
        final double cardWidth =
            (constraints.maxWidth - (gap * (itemCount - 1))) / itemCount;

        return SizedBox(
          height: cardHeight,
          child: Row(
            children: <Widget>[
              for (int index = 0; index < itemCount; index += 1) ...<Widget>[
                if (index > 0) SizedBox(width: gap),
                SizedBox(
                  width: cardWidth,
                  child: SixVisualAssetShimmer(
                    height: cardHeight,
                    borderRadius:
                        prominence == _AtendimentoActionProminence.primary
                            ? 22
                            : 18,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AtendimentoActionsRow extends StatelessWidget {
  const _AtendimentoActionsRow({
    required this.actions,
    required this.prominence,
    required this.onReorder,
    this.heightBoost = 0,
  });

  final List<_PrimaryActionData> actions;
  final _AtendimentoActionProminence prominence;
  final void Function(
    AtendimentoMobileCardPreferencia movido,
    AtendimentoMobileCardPreferencia destino,
  )
  onReorder;
  final double heightBoost;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double textScale = MediaQuery.textScalerOf(context).scale(1);
        final double gap =
            prominence == _AtendimentoActionProminence.primary ? 12 : 8;
        final double cardHeight =
            _resolveCardHeight(textScale: textScale) + heightBoost;
        final double cardWidth =
            (width - (gap * (actions.length - 1))) / actions.length;

        return SizedBox(
          key: ValueKey<String>('atendimento-actions-row-${prominence.name}'),
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int index = 0; index < actions.length; index += 1) ...[
                if (index > 0) SizedBox(width: gap),
                SizedBox(
                  width: cardWidth,
                  child: SixMobileReorderableCard<
                    AtendimentoMobileCardPreferencia
                  >(
                    value: actions[index].preferencia,
                    onReorder: onReorder,
                    feedbackWidth: cardWidth,
                    feedbackHeight: cardHeight,
                    handleColor: actions[index].accentColor,
                    handleOnLeft: true,
                    cardBuilder:
                        () => _PrimaryActionCard(
                          data: actions[index],
                          prominence: prominence,
                          availableRowWidth: width,
                        ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  double _resolveCardHeight({required double textScale}) {
    final double scaleExtra = (textScale - 1).clamp(0.0, 0.8).toDouble();
    if (prominence == _AtendimentoActionProminence.primary) {
      return 190 + (scaleExtra * 82);
    }
    return 146 + (scaleExtra * 58);
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.data,
    required this.prominence,
    required this.availableRowWidth,
  });

  final _PrimaryActionData data;
  final _AtendimentoActionProminence prominence;
  final double availableRowWidth;

  bool get _isPrimary => prominence == _AtendimentoActionProminence.primary;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool enabled = data.enabled && data.onTap != null;
    final String status = data.statusLabel ?? '';
    final String semanticSuffix = status;
    final String semanticLabel =
        semanticSuffix.isEmpty ? data.title : '${data.title}. $semanticSuffix';
    final double radius = _isPrimary ? 22 : 18;

    return Semantics(
      container: true,
      button: enabled,
      enabled: enabled,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.72,
        child: Container(
          key: ValueKey<String>('atendimento-action-${data.id}'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color:
                    _isPrimary
                        ? data.brandEnd.withAlpha(isDark ? 30 : 18)
                        : colors.navigationShadow.withAlpha(18),
                blurRadius: _isPrimary ? 16 : 10,
                offset: Offset(0, _isPrimary ? 8 : 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(radius),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              key: ValueKey<String>('atendimento-action-surface-${data.id}'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color.alphaBlend(
                      data.brandStart.withAlpha(isDark ? 27 : 15),
                      colors.surface,
                    ),
                    Color.alphaBlend(
                      data.brandEnd.withAlpha(isDark ? 17 : 8),
                      colors.surface,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color:
                      enabled
                          ? data.accentColor.withAlpha(_isPrimary ? 68 : 46)
                          : colors.border,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(radius),
                onTap: enabled ? data.onTap : null,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (
                          BuildContext context,
                          BoxConstraints constraints,
                        ) {
                          if (data.contextualImageFullCard &&
                              data.contextualImageUrl != null &&
                              !kIsWeb) {
                            return _ContextualFullCardContent(
                              data: data,
                              enabled: enabled,
                              prominence: prominence,
                              constraints: constraints,
                              rowWidth: availableRowWidth,
                            );
                          }

                          return Padding(
                            padding:
                                _isPrimary
                                    ? EdgeInsets.fromLTRB(10, 11, 10, 10)
                                    : EdgeInsets.fromLTRB(7, 8, 7, 8),
                            child: _ActionCardContent(
                              data: data,
                              enabled: enabled,
                              prominence: prominence,
                              constraints: constraints,
                              rowWidth: availableRowWidth,
                            ),
                          );
                        },
                      ),
                    ),
                    if (_isPrimary)
                      Positioned(
                        top: 0,
                        left: 22,
                        right: 22,
                        child: SizedBox(
                          height: 1.4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  data.brandStart.withAlpha(0),
                                  data.brandStart.withAlpha(190),
                                  data.brandEnd.withAlpha(190),
                                  data.brandEnd.withAlpha(0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContextualFullCardContent extends StatelessWidget {
  const _ContextualFullCardContent({
    required this.data,
    required this.enabled,
    required this.prominence,
    required this.constraints,
    required this.rowWidth,
  });

  final _PrimaryActionData data;
  final bool enabled;
  final _AtendimentoActionProminence prominence;
  final BoxConstraints constraints;
  final double rowWidth;

  bool get _isPrimary => prominence == _AtendimentoActionProminence.primary;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final bool compactWidth =
        constraints.maxWidth < (_isPrimary ? 150 : 102) || rowWidth < 340;
    final bool compact = compactWidth || textScale >= 1.22;
    final double titleSize =
        _isPrimary ? (compact ? 13.4 : 15.4) : (compact ? 10.2 : 11.2);
    final String url = data.contextualImageUrl!;

    final Widget localFallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(
              data.brandStart.withAlpha(isDark ? 38 : 22),
              colors.surface,
            ),
            Color.alphaBlend(
              data.brandEnd.withAlpha(isDark ? 28 : 14),
              colors.surface,
            ),
          ],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: enabled ? 0.9 : 0.5,
          child: SixImagemCanetinha(
            assetContorno: data.assetContorno,
            assetAcento: data.assetAcento,
            largura: _isPrimary ? 92 : 58,
            altura: _isPrimary ? 92 : 58,
            fit: BoxFit.contain,
            corContorno: colors.titleText,
            corAcento: data.accentColor,
            opacidadeContorno: enabled ? 1 : 0.46,
            opacidadeAcento: enabled ? 1 : 0.48,
            reforcoContorno: _isPrimary ? 0.62 : 0.82,
            reforcoAcento: _isPrimary ? 0.72 : 0.92,
            opacidadeReforco: isDark ? 0.52 : 0.44,
            opacidadeBrilho: 0,
          ),
        ),
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        SixCachedNetworkImage(
          imageUrl: url,
          key: ValueKey<String>('atendimento-contextual-fullcard-${data.id}-$url'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          placeholder: const SixVisualAssetShimmer(
            borderRadius: 0,
          ),
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stack,
          ) {
            debugPrint(
              '[AtendimentoMobile] Falha ao carregar full-card '
              'url=$url error=$error',
            );
            return localFallback;
          },
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const <double>[0, 0.5, 0.76, 1],
              colors: <Color>[
                Colors.transparent,
                colors.surface.withAlpha(isDark ? 18 : 10),
                colors.surface.withAlpha(isDark ? 150 : 175),
                colors.surface.withAlpha(isDark ? 246 : 250),
              ],
            ),
          ),
        ),
        Positioned(
          left: _isPrimary ? 10 : 6,
          right: _isPrimary ? 10 : 6,
          bottom: _isPrimary ? 10 : 7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                data.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: enabled ? data.accentColor : colors.mutedText,
                  fontSize: titleSize,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  shadows: <Shadow>[
                    Shadow(
                      color: colors.surface.withAlpha(isDark ? 210 : 245),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              SizedBox(height: _isPrimary ? 8 : 5),
              _ActionIndicator(
                accentColor: data.accentColor,
                enabled: enabled,
                statusLabel: data.statusLabel,
                compact: !_isPrimary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionCardContent extends StatelessWidget {
  const _ActionCardContent({
    required this.data,
    required this.enabled,
    required this.prominence,
    required this.constraints,
    required this.rowWidth,
  });

  final _PrimaryActionData data;
  final bool enabled;
  final _AtendimentoActionProminence prominence;
  final BoxConstraints constraints;
  final double rowWidth;

  bool get _isPrimary => prominence == _AtendimentoActionProminence.primary;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final bool compactWidth =
        constraints.maxWidth < (_isPrimary ? 150 : 102) || rowWidth < 340;
    final bool compactText = textScale >= 1.22;
    final bool compact = compactWidth || compactText;
    final double extraHeightFactor =
        ((constraints.maxHeight - (_isPrimary ? 168 : 130)) /
                (_isPrimary ? 120 : 90))
            .clamp(0.0, 1.0)
            .toDouble();
    final double imageCircleSize =
        _isPrimary
            ? ((compact ? 68 : 82) + (extraHeightFactor * 10)) * 1.4
            : ((compact ? 45 : 54) + (extraHeightFactor * 8)) * 1.4;
    final double imageSize =
        _isPrimary
            ? ((compact ? 60 : 72) + (extraHeightFactor * 9)) * 1.4
            : ((compact ? 40 : 48) + (extraHeightFactor * 7)) * 1.4;
    final double titleSize =
        _isPrimary
            ? (compact ? 13.1 : 15.0) + (extraHeightFactor * 0.8)
            : (compact ? 10.4 : 11.4) + (extraHeightFactor * 0.7);
    final double contentGap = _isPrimary ? 10 : 8;
    final EdgeInsetsGeometry titlePadding = EdgeInsets.symmetric(
      horizontal: _isPrimary ? 10 : 8,
    );
    final Color illustrationStart =
        isDark
            ? Color.lerp(
              data.brandStart,
              colors.titleText,
              _isPrimary ? 0.18 : 0.26,
            )!
            : data.brandStart;
    final Color illustrationEnd =
        isDark
            ? Color.lerp(
              data.brandEnd,
              colors.titleText,
              _isPrimary ? 0.46 : 0.54,
            )!
            : data.brandEnd;
    final Color illustrationAccent =
        isDark
            ? Color.lerp(data.accentColor, colors.titleText, 0.24)!
            : data.accentColor;

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                key: ValueKey<String>('atendimento-action-halo-${data.id}'),
                width: imageCircleSize,
                height: imageCircleSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      data.brandStart.withAlpha(
                        enabled
                            ? isDark
                                ? (_isPrimary ? 96 : 82)
                                : (_isPrimary ? 60 : 52)
                            : 18,
                      ),
                      data.brandEnd.withAlpha(
                        enabled
                            ? isDark
                                ? (_isPrimary ? 64 : 54)
                                : (_isPrimary ? 40 : 34)
                            : 12,
                      ),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: data.accentColor.withAlpha(
                      enabled ? (_isPrimary ? 104 : 88) : 26,
                    ),
                  ),
                  boxShadow:
                      isDark && enabled
                          ? <BoxShadow>[
                            BoxShadow(
                              color: data.brandStart.withAlpha(
                                _isPrimary ? 72 : 58,
                              ),
                              blurRadius: _isPrimary ? 22 : 16,
                              spreadRadius: _isPrimary ? 0.4 : 0,
                            ),
                          ]
                          : const <BoxShadow>[],
                ),
                child: Center(
                  child: _ActionIllustration(
                    data: data,
                    imageSize: imageSize,
                    enabled: enabled,
                    isDark: isDark,
                    colors: colors,
                    illustrationStart: illustrationStart,
                    illustrationEnd: illustrationEnd,
                    illustrationAccent: illustrationAccent,
                    isPrimary: _isPrimary,
                  ),
                ),
              ),
              SizedBox(height: contentGap),
              Padding(
                padding: titlePadding,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    data.title,
                    maxLines: _isPrimary ? 2 : 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: enabled ? data.accentColor : colors.mutedText,
                      fontSize: titleSize,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: contentGap),
        _ActionIndicator(
          accentColor: data.accentColor,
          enabled: enabled,
          statusLabel: data.statusLabel,
          compact: !_isPrimary,
        ),
      ],
    );
  }
}

class _ActionIllustration extends StatelessWidget {
  const _ActionIllustration({
    required this.data,
    required this.imageSize,
    required this.enabled,
    required this.isDark,
    required this.colors,
    required this.illustrationStart,
    required this.illustrationEnd,
    required this.illustrationAccent,
    required this.isPrimary,
  });

  final _PrimaryActionData data;
  final double imageSize;
  final bool enabled;
  final bool isDark;
  final SixMobileColorScheme colors;
  final Color illustrationStart;
  final Color illustrationEnd;
  final Color illustrationAccent;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = SixImagemCanetinha(
      assetContorno: data.assetContorno,
      assetAcento: data.assetAcento,
      largura: imageSize,
      altura: imageSize,
      fit: BoxFit.contain,
      corContorno: colors.titleText,
      corAcento: data.accentColor,
      gradienteContorno: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[illustrationStart, illustrationEnd],
      ),
      gradienteAcento: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[illustrationAccent, illustrationEnd],
      ),
      opacidadeContorno: enabled ? 1 : 0.46,
      opacidadeAcento: enabled ? 1 : 0.48,
      reforcoContorno: isPrimary ? 0.62 : 0.82,
      reforcoAcento: isPrimary ? 0.72 : 0.92,
      opacidadeReforco: isDark ? 0.52 : 0.44,
      opacidadeBrilho:
          enabled
              ? isDark
                  ? 0.62
                  : 0.24
              : 0,
      desfoqueBrilho: isPrimary ? 4.8 : 3.4,
    );

    final String? url = data.contextualImageUrl;
    if (url == null || url.isEmpty || kIsWeb) return fallback;

    return SixCachedNetworkImage(
      imageUrl: url,
      key: ValueKey<String>('atendimento-contextual-image-${data.id}'),
      width: imageSize,
      height: imageSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      placeholder: SixVisualAssetShimmer(
        width: imageSize,
        height: imageSize,
        borderRadius: 999,
      ),
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        debugPrint(
          '[AtendimentoMobile] Falha ao carregar imagem contextual '
          'url=$url error=$error',
        );
        return fallback;
      },
    );
  }
}

class _ActionIndicator extends StatelessWidget {
  const _ActionIndicator({
    required this.accentColor,
    required this.enabled,
    required this.statusLabel,
    required this.compact,
  });

  final Color accentColor;
  final bool enabled;
  final String? statusLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    if (!enabled && statusLabel != null && statusLabel!.isNotEmpty) {
      return _SoonChip(label: statusLabel!, compact: compact);
    }

    return ExcludeSemantics(
      child: Container(
        width: compact ? 23 : 28,
        height: compact ? 23 : 28,
        decoration: BoxDecoration(
          color: accentColor.withAlpha(enabled ? 22 : 12),
          shape: BoxShape.circle,
          border: Border.all(color: accentColor.withAlpha(enabled ? 58 : 28)),
        ),
        child: Icon(
          enabled ? Icons.arrow_forward_rounded : Icons.lock_outline_rounded,
          color: enabled ? accentColor : colors.mutedText,
          size: compact ? 13 : 15,
        ),
      ),
    );
  }
}

class _SoonChip extends StatelessWidget {
  const _SoonChip({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 70 : 118),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: colors.mutedText.withAlpha(18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.mutedText.withAlpha(35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.lock_outline_rounded,
              size: compact ? 10 : 12,
              color: colors.mutedText,
            ),
            SizedBox(width: compact ? 3 : 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.mutedText,
                  fontSize: compact ? 9 : 11,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionData {
  const _PrimaryActionData({
    required this.preferencia,
    required this.id,
    required this.title,
    required this.assetContorno,
    required this.assetAcento,
    this.contextualImageUrl,
    this.contextualImageFullCard = false,
    required this.accentColor,
    required this.brandStart,
    required this.brandEnd,
    required this.onTap,
    this.enabled = true,
    this.statusLabel,
  });

  final AtendimentoMobileCardPreferencia preferencia;
  final String id;
  final String title;
  final String assetContorno;
  final String assetAcento;
  final String? contextualImageUrl;
  final bool contextualImageFullCard;
  final Color accentColor;
  final Color brandStart;
  final Color brandEnd;
  final VoidCallback? onTap;
  final bool enabled;
  final String? statusLabel;
}
