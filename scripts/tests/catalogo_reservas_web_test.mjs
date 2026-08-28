import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

const model = readFileSync(
  'lib/data/models/catalogo_reserva_model.dart',
  'utf8',
);
const service = readFileSync(
  'lib/core/services/catalogo_reserva_service.dart',
  'utf8',
);
const screen = readFileSync(
  'lib/presentation/screens/catalogo_reservas_web.dart',
  'utf8',
);
const productScreen = readFileSync(
  'lib/presentation/screens/produto_lista_sub_painel_web.dart',
  'utf8',
);
const navigationRegistry = readFileSync(
  'lib/presentation/navigation/web_navigation_registry.dart',
  'utf8',
);
const mainWeb = readFileSync('lib/pagina_principal_web.dart', 'utf8');
const i18n = readFileSync('lib/l10n/six_i18n.dart', 'utf8');

test('service usa endpoints privados tenant-scoped com autenticacao', () => {
  assert.match(service, /\/private\/api\/catalogo-publico\/reservas/);
  assert.match(service, /'Authorization': 'Bearer \$token'/);
  assert.match(service, /'idUnicoDaEmpresa': empresaId/);
  assert.match(service, /_client\.get/);
  assert.match(service, /_client\.patch/);
  assert.match(service, /converter-em-venda/);
  assert.match(service, /_client\.post/);
});

test('model cobre todos os status persistidos pelo backend', () => {
  for (const status of [
    'RECEBIDA',
    'EM_ANALISE',
    'CONFIRMADA',
    'CANCELADA',
    'CONVERTIDA',
  ]) {
    assert.equal(model.includes(`'${status}'`), true);
  }
});

test('tela separa apresentacao da camada HTTP e usa loading padrao', () => {
  assert.equal(screen.includes("package:http"), false);
  assert.match(screen, /CatalogoReservaService/);
  assert.match(screen, /SixBackendLoading\.messages/);
  assert.match(screen, /LocaleSettingsProvider/);
});

test('tela permite filtrar, paginar, detalhar, atualizar e converter', () => {
  assert.match(screen, /_alterarFiltro/);
  assert.match(screen, /_buildPagination/);
  assert.match(screen, /_carregarDetalhe/);
  assert.match(screen, /_atualizarStatus/);
  assert.match(screen, /_converterEmVenda/);
  assert.match(screen, /CatalogoReservaStatus\.confirmada/);
  assert.match(screen, /CatalogoReservaStatus\.convertida/);
});

test('menu Catalogo centraliza o acesso as reservas', () => {
  assert.match(navigationRegistry, /WebNavigationIds\.operationsReservations/);
  assert.match(
    navigationRegistry,
    /web\.navigation\.catalog\.reservations/,
  );
  assert.match(
    navigationRegistry,
    /WebNavigationDestination\.operationsReservations/,
  );
  assert.match(mainWeb, /CatalogoReservasWebPage/);
  assert.doesNotMatch(productScreen, /CatalogoReservasWeb/);
  assert.doesNotMatch(productScreen, /produto\.webList\.catalogReservations/);
});

test('novas traducoes possuem paridade pt en es', () => {
  for (const key of [
    'web.navigation.catalog.reservations',
    'catalogReservations.title',
    'catalogReservations.status.received',
    'catalogReservations.status.analysis',
    'catalogReservations.status.confirmed',
    'catalogReservations.status.cancelled',
    'catalogReservations.status.converted',
    'catalogReservations.convert.action',
    'catalogReservations.convert.confirmTitle',
    'catalogReservations.convert.success',
    'catalogReservations.convert.error.stock',
    'catalogReservations.empty',
    'catalogReservations.error',
  ]) {
    const escaped = key.replaceAll('.', '\\.');
    const occurrences = i18n.match(new RegExp(`'${escaped}'`, 'g')) || [];
    assert.equal(occurrences.length, 3, `${key} deve existir em pt/en/es`);
  }
});
