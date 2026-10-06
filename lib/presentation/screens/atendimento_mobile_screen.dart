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
            ordemPadrao: const <AtendimentoMobileCardPreferencia>[
              AtendimentoMobileCardPreferencia.novaVenda,
              AtendimentoMobileCardPreferencia.novoServico,
              AtendimentoMobileCardPreferencia.receber,
              AtendimentoMobileCardPreferencia.devolucao,
              AtendimentoMobileCardPreferencia.operacoesCaixa,
            ],
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
      title: '',
      enableAnimatedBackground: false,
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
    final actions = _orderedActions();
    final grid = actions.where((item) => item.id != 'cash').toList();
    final cash = actions.firstWhere((item) => item.id == 'cash');
    return SafeArea(
      top: false,
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 24),
        children: <Widget>[
          Text(
            _txt('atendimento.mobile.title', 'Atendimento'),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: _colors.titleText, fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _txt('atendimento.mobile.editorialSubtitle', 'Como podemos ajudar hoje?'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: _colors.mutedText),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final height = width * 1.12 + (scale - 1).clamp(0.0, 2.0).toDouble() * 48;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                for (int i = 0; i < grid.length; i++)
                  SizedBox(
                    width: width,
                    height: height,
                    child: _businessAssetsLoading
                        ? const SixVisualAssetShimmer(borderRadius: 18)
                        : SixStaggeredEntry(
                            delay: Duration(milliseconds: 50 + i * 35),
                            child: SixMobileReorderableCard<AtendimentoMobileCardPreferencia>(
                              value: grid[i].preferencia,
                              onReorder: _ordemCardsController.reordenar,
                              feedbackWidth: width,
                              feedbackHeight: height,
                              handleColor: _colors.mutedText,
                              showHandle: false,
                              cardBuilder: () => _AtendimentoEditorialCard(data: grid[i]),
                            ),
                          ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            height: 116 + (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0.0, 2.0).toDouble() * 64,
            child: _businessAssetsLoading
                ? const SixVisualAssetShimmer(borderRadius: 18)
                : _AtendimentoEditorialCard(
                    data: cash,
                    horizontal: true,
                    subtitle: _txt('atendimento.mobile.cashSummary', 'Abertura, movimentações e fechamento'),
                  ),
          ),
        ],
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
            onTap: _openSalesMenu,
            enabled: true,
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
            onTap: _openServicesMenu,
            enabled: true,
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
            onTap: () => _go(ReceberMobileScreen()),
            enabled: true,
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
            onTap: _openCashOperations,
            enabled: true,
          ),
          AtendimentoMobileCardPreferencia.devolucao: _PrimaryActionData(
            preferencia: AtendimentoMobileCardPreferencia.devolucao,
            id: 'return',
            title: _txt('atendimento.mobile.returnsShort', 'Devoluções'),
            assetContorno: _returnAssetContorno,
            assetAcento: _returnAssetAcento,
            contextualImageUrl: _businessImageUrl(
              AtendimentoMobileAssetSlot.devolucao,
            ),
            contextualImageFullCard: _businessImageFullCard(
              AtendimentoMobileAssetSlot.devolucao,
            ),
            onTap: () => _go(DevolucoesProdutosMobileScreen()),
            enabled: true,
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

/// Mobile-only composition: neutral illustrated actions with the whole card tappable.
class _AtendimentoEditorialCard extends StatelessWidget {
  const _AtendimentoEditorialCard({required this.data, this.horizontal = false, this.subtitle});

  final _PrimaryActionData data;
  final bool horizontal;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.sixMobileColors;
    final enabled = data.enabled && data.onTap != null;
    final url = data.contextualImageUrl;
    final fallback = ColoredBox(
      color: const Color(0xFF25282C),
      child: Center(
        child: SixImagemCanetinha(
          assetContorno: data.assetContorno,
          assetAcento: data.assetAcento,
          largura: 72,
          altura: 72,
          fit: BoxFit.contain,
          corContorno: Colors.white70,
          corAcento: Colors.white70,
        ),
      ),
    );
    final illustration = url == null || kIsWeb
        ? fallback
        : SixCachedNetworkImage(
            key: ValueKey<String>('atendimento-${data.id}-$url'),
            imageUrl: url,
            fit: data.contextualImageFullCard ? BoxFit.cover : BoxFit.contain,
            alignment: horizontal ? const Alignment(0, -0.35) : Alignment.topCenter,
            placeholder: const SixVisualAssetShimmer(borderRadius: 0),
            errorBuilder: (_, __, ___) => fallback,
          );
    return Semantics(
      button: true,
      enabled: enabled,
      label: subtitle == null ? data.title : '${data.title}. $subtitle',
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Material(
          key: ValueKey<String>('atendimento-action-${data.id}'),
          color: const Color(0xFF202327),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ExcludeSemantics(
                child: horizontal
                    ? Row(children: <Widget>[
                        const Spacer(flex: 4),
                        Expanded(flex: 6, child: SizedBox.expand(child: illustration)),
                      ])
                    : illustration,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: horizontal ? Alignment.centerLeft : Alignment.topCenter,
                    end: horizontal ? Alignment.centerRight : Alignment.bottomCenter,
                    colors: horizontal
                        ? const <Color>[Color(0xFF202327), Color(0xF2202327), Color(0x00202327)]
                        : const <Color>[Colors.transparent, Color(0x08000000), Color(0xE6000000)],
                    stops: horizontal ? const <double>[0, .40, .85] : const <double>[0, .45, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: horizontal ? Alignment.centerLeft : Alignment.bottomLeft,
                  child: FractionallySizedBox(
                    widthFactor: horizontal ? .66 : 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(data.title, style: const TextStyle(
                          color: Colors.white, fontSize: 18, height: 1.12, fontWeight: FontWeight.w700,
                        )),
                        if (subtitle != null) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(subtitle!, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Ink above image keeps press feedback visible on the entire card.
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: enabled ? data.onTap : null,
                    splashColor: colors.titleText.withValues(alpha: .10),
                    highlightColor: Colors.white.withValues(alpha: .08),
                  ),
                ),
              ),
            ],
          ),
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
    required this.onTap,
    this.enabled = true,
  });

  final AtendimentoMobileCardPreferencia preferencia;
  final String id;
  final String title;
  final String assetContorno;
  final String assetAcento;
  final String? contextualImageUrl;
  final bool contextualImageFullCard;
  final VoidCallback? onTap;
  final bool enabled;
}
