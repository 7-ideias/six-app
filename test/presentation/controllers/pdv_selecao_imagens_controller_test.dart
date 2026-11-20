import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/presentation/components/pdv_categoria_button.dart';
import 'package:sixpos/presentation/components/six_cached_network_image.dart';
import 'package:sixpos/presentation/components/six_web_cached_image_provider.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/core/services/perfil_negocio_service.dart';
import 'package:sixpos/core/services/visual_asset_manifest_cache_service.dart';
import 'package:sixpos/core/services/visual_asset_sync_service.dart';
import 'package:sixpos/data/models/empresa_model.dart';
import 'package:sixpos/data/models/pdv_selecao_assets.dart';
import 'package:sixpos/presentation/controllers/pdv_selecao_imagens_controller.dart';
import 'package:sixpos/providers/empresa_provider.dart';

class _Auth extends Fake implements AuthService {
  @override
  Future<String?> getAccessToken() async => 'token-de-teste';
  @override
  Future<String?> getEmpresaId() async => 'loja';
}

class _Perfil extends Fake implements PerfilNegocioService {
  String empresa = 'loja-a';
  final requests = <Completer<Map<String, String>>>[];

  @override
  Future<String> empresaAtual() async => empresa;
  @override
  Future<Map<String, String>> imagensSelecaoPdv(String empresaId) {
    final pending = Completer<Map<String, String>>();
    requests.add(pending);
    return pending.future;
  }

  @override
  void dispose() {}
}

class _Sync extends Fake implements VisualAssetSyncService {
  final events = StreamController<void>.broadcast(sync: true);
  @override
  String environment = 'DEV';
  @override
  String version = '202611201755';
  @override
  Stream<void> get changes => events.stream;
  @override
  Future<void> restoreLocalState() async {}
  @override
  Future<bool> initialize() async => false;

  void publish(String next) {
    version = next;
    events.add(null);
  }
}

class _Manifest extends Fake implements VisualAssetManifestCacheService {
  Map<String, dynamic> cached = {'PRODUTO': 'https://assets.example/local-a'};
  bool fail = false;
  final saved = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>?> load({
    required String kind,
    required String companyId,
    required String environment,
    String? assetsVersion,
  }) async {
    if (fail) throw StateError('cache unavailable');
    return cached;
  }

  @override
  Future<bool> prefetchAndSave({
    required String kind,
    required String companyId,
    required String environment,
    required String assetsVersion,
    required Map<String, dynamic> payload,
    required Iterable<String> imageUrls,
    bool Function()? stillCurrent,
  }) async {
    if (stillCurrent?.call() == false) return false;
    saved.add(payload);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Perfil service;
  late _Sync sync;
  late _Manifest cache;
  late PdvSelecaoImagensController state;
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test(
    'preserva a versão e direciona o loopback local ao host do emulador',
    () {
      expect(
        pdvSelecaoUrls({
          'PRODUTO': 'http://localhost:8082/public/api/assets/p.webp?v=7',
          'SERVICO': 'https://cdn.example/s.webp?v=3',
          'OUTRO': 'https://cdn.example/x',
        }, apiBaseUrl: 'http://10.0.2.2:8082'),
        {
          'PRODUTO': 'http://10.0.2.2:8082/public/api/assets/p.webp?v=7',
          'SERVICO': 'https://cdn.example/s.webp?v=3',
        },
      );
      expect(
        pdvSelecaoUrls({
          'PRODUTO': 'sem-url',
          'SERVICO': 'http://example.com/s.webp',
        }),
        isEmpty,
      );
    },
  );

  test('consulta a plataforma atual com token e comércio', () async {
    final api = PerfilNegocioService(
      authService: _Auth(),
      client: MockClient((request) async {
        expect(request.url.path, '/private/api/pdv/selecao/assets');
        expect(
          request.url.queryParameters['plataforma'],
          kIsWeb ? 'WEB' : 'MOBILE',
        );
        expect(request.headers['idUnicoDaEmpresa'], 'loja');
        expect(request.headers['authorization'], 'Bearer token-de-teste');
        return http.Response('{"SERVICO":"https://assets.example/s?v=1"}', 200);
      }),
    );
    addTearDown(api.dispose);
    expect(await api.imagensSelecaoPdv('loja'), {
      'SERVICO': 'https://assets.example/s?v=1',
    });
  });

  testWidgets(
    'cartões recebem publicação e retirada com a categoria selecionada',
    (tester) async {
      const product = 'https://assets.example/p.webp?v=2';
      const serviceUrl = 'https://assets.example/s.webp?v=1';
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawColor(const Color(0xFF425777), ui.BlendMode.src);
      final picture = recorder.endRecording();
      final pixel = picture.toImageSync(1, 1);
      picture.dispose();
      addTearDown(pixel.dispose);
      for (final url in [product, serviceUrl]) {
        final ImageProvider provider =
            kIsWeb
                ? SixWebCachedImageProvider(url)
                : CachedNetworkImageProvider(url);
        imageCache.putIfAbsent(
          provider,
          () => OneFrameImageStreamCompleter(
            Future.value(ImageInfo(image: pixel.clone())),
          ),
        );
      }
      cache.cached = {};
      String category = 'PRODUTO';
      state.initialize();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder:
                    (context, setState) => PdvCategorias(
                      tipo: category,
                      onChanged: (value) => setState(() => category = value),
                      photoHeight: 76,
                      spacing: 8,
                      surface: Colors.white,
                      foreground: Colors.black,
                      accent: Colors.blue,
                      border: Colors.grey,
                    ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SixCachedNetworkImage), findsNothing);
      service.requests.single.complete({'SERVICO': serviceUrl});
      await tester.pumpAndSettle();
      expect(find.byType(SixCachedNetworkImage), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pdv-categoria-SERVICO')));
      sync.publish('202611201800');
      await tester.pump();
      service.requests.last.complete({
        'PRODUTO': product,
        'SERVICO': serviceUrl,
      });
      await tester.pumpAndSettle();
      expect(find.byType(SixCachedNetworkImage), findsNWidgets(2));
      sync.publish('202611201801');
      await tester.pump();
      service.requests.last.complete({});
      await tester.pumpAndSettle();
      expect(find.byType(SixCachedNetworkImage), findsNothing);
      final selected = tester.widget<PdvCategoriaButton>(
        find.byKey(const ValueKey('pdv-categoria-SERVICO')),
      );
      expect(selected.selected, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  setUp(() {
    service = _Perfil();
    sync = _Sync();
    cache = _Manifest();
    state = PdvSelecaoImagensController(
      service: service,
      sync: sync,
      cache: cache,
    );
  });
  tearDown(() async {
    state.dispose();
    await sync.events.close();
    EmpresaProvider().clear();
  });

  test(
    'restaura, substitui e remove arte sem aceitar resposta de versão anterior',
    () async {
      state.initialize();
      await settle();
      expect(state.url('PRODUTO'), 'https://assets.example/local-a');
      sync.publish('202611201800');
      await settle();
      service.requests[1].complete({
        'PRODUTO': 'publicado',
        'SERVICO': 'reparo',
      });
      await settle();
      service.requests[0].complete({'PRODUTO': 'atrasado'});
      await settle();
      expect(state.url('PRODUTO'), 'publicado');
      expect(state.url('SERVICO'), 'reparo');
      sync.publish('202611201801');
      await settle();
      service.requests.last.complete({});
      await settle();
      expect(state.url('PRODUTO'), isNull);
      expect(state.url('SERVICO'), isNull);
      expect(cache.saved, [
        {'PRODUTO': 'publicado', 'SERVICO': 'reparo'},
        {},
      ]);
    },
  );

  test(
    'troca de comércio descarta a consulta em andamento mesmo sem cache local',
    () async {
      cache.fail = true;
      state.initialize();
      await settle();
      service.empresa = 'loja-b';
      EmpresaProvider().setEmpresa(
        const EmpresaModel(
          nomeEmpresa: 'B',
          nomeFantasia: 'B',
          documentoNoBrasilCNPJ: '',
        ),
      );
      await settle();
      service.requests.last.complete({'SERVICO': 'loja-b'});
      service.requests.first.complete({'PRODUTO': 'loja-a'});
      await settle();
      expect(state.url('PRODUTO'), isNull);
      expect(state.url('SERVICO'), 'loja-b');
    },
  );

  test(
    'manifesto persistido só restaura na empresa, ambiente e versão correspondentes',
    () async {
      SharedPreferences.setMockInitialValues({});
      final cache = VisualAssetManifestCacheService.instance;
      Future<Map<String, dynamic>?> read(
        String company,
        String env,
        String version,
      ) => cache.load(
        kind: 'pdv_selecao_mobile',
        companyId: company,
        environment: env,
        assetsVersion: version,
      );
      expect(
        await cache.prefetchAndSave(
          kind: 'pdv_selecao_mobile',
          companyId: 'a',
          environment: 'DEV',
          assetsVersion: 'v1',
          payload: {},
          imageUrls: [],
        ),
        isTrue,
      );
      expect(await read('a', 'DEV', 'v1'), {});
      expect(await read('a', 'LIVE', 'v1'), isNull);
      expect(await read('b', 'DEV', 'v1'), isNull);
      expect(await read('a', 'DEV', 'v2'), isNull);
      expect(
        await cache.prefetchAndSave(
          kind: 'pdv_selecao_mobile',
          companyId: 'a',
          environment: 'DEV',
          assetsVersion: 'v2',
          payload: {},
          imageUrls: [],
          stillCurrent: () => false,
        ),
        isFalse,
      );
      expect(await read('a', 'DEV', 'v1'), {});
    },
    skip: kIsWeb,
  );
}
