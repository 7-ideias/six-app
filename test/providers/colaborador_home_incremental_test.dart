import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/catalogo_reserva_service.dart';
import 'package:sixpos/data/models/catalogo_reserva_model.dart';
import 'package:sixpos/data/models/consulta_vendas_models.dart';
import 'package:sixpos/data/models/venda_nao_liquidada_models.dart';
import 'package:sixpos/data/services/caixa/venda_nao_liquidada_api_client.dart';
import 'package:sixpos/data/services/vendas/consulta_vendas_api_client.dart';
import 'package:sixpos/providers/colaborador_home_operacional_provider.dart';

void main() {
  test('reservations appear without waiting for sales', () async {
    final sales = _Sales();
    final provider = _provider(sales);
    addTearDown(provider.dispose);
    final pending = provider.load(
      canAccessSales: true,
      canAccessServices: false,
      canAccessReservations: true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(provider.reservationsLoaded, isTrue);
    expect(provider.salesLoaded, isFalse);
    expect(provider.hasLoaded, isFalse);
    expect(provider.reservasAguardandoAcao, 4);
    sales.result.complete(ConsultaVendasResponse.fromJson({}));
    await pending;
    expect(provider.salesLoaded, isTrue);
    expect(provider.hasLoaded, isTrue);
  });

  test('clear and dispose reject old responses', () async {
    final sales = _Sales();
    final provider = _provider(sales);
    final pending = provider.load(
      canAccessSales: true,
      canAccessServices: false,
      canAccessReservations: false,
    );
    await Future<void>.delayed(Duration.zero);
    provider.clear();
    provider.dispose();
    sales.result.complete(ConsultaVendasResponse.fromJson({}));
    await pending;
    expect(provider.vendasMes, isNull);
    expect(provider.salesLoaded, isFalse);
  });
}

ColaboradorHomeOperacionalProvider _provider(_Sales sales) =>
    ColaboradorHomeOperacionalProvider(
      consultaVendasApiClient: sales,
      vendaNaoLiquidadaApiClient: _OpenSales(),
      catalogoReservaService: _Reservations(),
      userIdProvider: () async => 'user-a',
    );

class _Sales implements ConsultaVendasApiClient {
  @override
  Future<VendaDetalheResponse> detalhar(String identificador) =>
      throw UnsupportedError('Not used by the home');
  final result = Completer<ConsultaVendasResponse>();
  @override
  Future<ConsultaVendasResponse> consultar(ConsultaVendasFiltro filtro) =>
      result.future;
}

class _OpenSales extends VendaNaoLiquidadaApiClient {
  @override
  Future<List<VendaNaoLiquidadaModel>> listar() async => [];
}

class _Reservations extends CatalogoReservaService {
  @override
  Future<CatalogoReservaPaginaModel> listar({
    CatalogoReservaStatus? status,
    int pagina = 0,
    int tamanho = 20,
  }) async => const CatalogoReservaPaginaModel(
    reservas: [],
    pagina: 0,
    tamanho: 1,
    totalPaginas: 2,
    totalElementos: 2,
  );
}
