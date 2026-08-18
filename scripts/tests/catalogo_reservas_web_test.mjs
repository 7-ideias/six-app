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
const i18n = readFileSync('lib/l10n/six_i18n.dart', 'utf8');

test('service usa endpoints privados tenant-scoped com autenticacao', () => {
  assert.match(service, /\/private\/api\/catalogo-publico\/reservas/);
  assert.match(service, /'Authorization': 'Bearer \$token'/);
  assert.match(service, /'idUnicoDaEmpresa': empresaId/);
  assert.match(service, /_client\.get/);
  assert.match(service, /_client\.patch/);
});

test('model cobre todos os status persistidos pelo backend', () => {
  for (const status of [
    'RECEBIDA',
    'EM_ANALISE',
    'CONFIRMADA',
    'CANCELADA',
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

test('tela permite filtrar, paginar, detalhar e atualizar status', () => {
  assert.match(screen, /_alterarFiltro/);
  assert.match(screen, /_buildPagination/);
  assert.match(screen, /_carregarDetalhe/);
  assert.match(screen, /_atualizarStatus/);
});

test('listagem de produtos oferece acesso as reservas', () => {
  assert.match(productScreen, /CatalogoReservasWebDialog/);
  assert.match(productScreen, /produto\.webList\.catalogReservations/);
});

test('novas traducoes possuem paridade pt en es', () => {
  for (const key of [
    'produto.webList.catalogReservations',
    'catalogReservations.title',
    'catalogReservations.status.received',
    'catalogReservations.status.analysis',
    'catalogReservations.status.confirmed',
    'catalogReservations.status.cancelled',
    'catalogReservations.empty',
    'catalogReservations.error',
  ]) {
    const escaped = key.replaceAll('.', '\\.');
    const occurrences = i18n.match(new RegExp(`'${escaped}'`, 'g')) || [];
    assert.equal(occurrences.length, 3, `${key} deve existir em pt/en/es`);
  }
});
