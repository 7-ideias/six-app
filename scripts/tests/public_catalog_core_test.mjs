import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

import {
  CATALOG_DICTIONARY,
  CatalogHttpError,
  CatalogTokenError,
  CatalogValidationError,
  buildCatalogReservationPayload,
  calculateCatalogSelection,
  catalogErrorKey,
  createCatalogEndpoint,
  createReservationEndpoint,
  fetchPublicCatalog,
  getCatalogTokenFromSearch,
  normalizeCatalogResponse,
  setCatalogSelectionQuantity,
  submitCatalogReservation,
} from '../../web/site-assets/js/catalog-core.mjs';
import { assertPublicDictionaryParity } from '../../web/site-assets/js/public-locale.mjs';

const token = 'abcdefghijklmnopqrstuvwx12345678';
const responseBody = {
  locale: 'pt-BR',
  currencyCode: 'BRL',
  geradoEm: '2026-08-18T18:00:00Z',
  empresa: {
    nomeEmpresa: 'Empresa Teste',
    nomeFantasia: 'Loja Teste',
    telefone: '4730000000',
    whatsapp: '5547999999999',
    email: 'contato@example.com',
    site: 'https://example.com',
    endereco: 'Rua Teste, 1',
    logoBase64: '',
    horariosAtendimento: [],
  },
  produtos: [
    {
      id: 'produto-1',
      nomeProduto: 'Tela A10',
      modeloProduto: 'A10',
      tipoProduto: 'PRODUTO',
      precoVenda: 280,
      imagemUrl: '',
      imagemBase64: '',
    },
    {
      id: 'produto-2',
      nomeProduto: 'Bateria',
      modeloProduto: '',
      tipoProduto: 'PRODUTO',
      precoVenda: 150,
      imagemUrl: '',
      imagemBase64: '',
    },
  ],
};

test('token e endpoints publicos preservam apenas o identificador opaco', () => {
  assert.equal(getCatalogTokenFromSearch(`?token=${token}`), token);
  assert.equal(
    createCatalogEndpoint('https://api.sixappback.com/', token),
    `https://api.sixappback.com/public/api/catalogos/${token}`,
  );
  assert.equal(
    createReservationEndpoint('https://api.sixappback.com', token),
    `https://api.sixappback.com/public/api/catalogos/${token}/reservas`,
  );
  assert.throws(() => getCatalogTokenFromSearch('?token=curto'), CatalogTokenError);
});

test('catalogo normaliza empresa, regionalizacao e produtos', () => {
  const catalog = normalizeCatalogResponse(responseBody);

  assert.equal(catalog.company.name, 'Loja Teste');
  assert.equal(catalog.currencyCode, 'BRL');
  assert.equal(catalog.products.length, 2);
  assert.equal(catalog.products[0].price, 280);
});

test('selecao consolida quantidade e total sem alterar catalogo', () => {
  const catalog = normalizeCatalogResponse(responseBody);
  let selection = setCatalogSelectionQuantity({}, 'produto-1', 2);
  selection = setCatalogSelectionQuantity(selection, 'produto-2', 1);
  const summary = calculateCatalogSelection(catalog, selection);

  assert.equal(summary.quantity, 3);
  assert.equal(summary.total, 710);
  assert.equal(catalog.products[0].price, 280);
});

test('payload envia somente ids, quantidades e contato informado', () => {
  const payload = buildCatalogReservationPayload({
    idempotencyKey: '5b3cbf3e-62dc-49d1-b7cb-729501292524',
    name: ' Carlos ',
    phone: '47999999999',
    email: '',
    notes: 'Preferência preta',
    selection: { 'produto-1': 2 },
  });

  assert.deepEqual(payload, {
    idempotencyKey: '5b3cbf3e-62dc-49d1-b7cb-729501292524',
    cliente: { nome: 'Carlos', telefone: '47999999999', email: null },
    itens: [{ idProduto: 'produto-1', quantidade: 2 }],
    observacao: 'Preferência preta',
  });
  assert.equal(Object.hasOwn(payload.itens[0], 'precoVenda'), false);
});

test('payload valida nome, contato, email e itens antes do envio', () => {
  const base = {
    idempotencyKey: '5b3cbf3e-62dc-49d1-b7cb-729501292524',
    name: 'Carlos',
    phone: '47999999999',
    email: '',
    notes: '',
    selection: { 'produto-1': 1 },
  };

  assert.throws(
    () => buildCatalogReservationPayload({ ...base, name: '' }),
    (error) => error instanceof CatalogValidationError && error.code === 'name',
  );
  assert.throws(
    () => buildCatalogReservationPayload({ ...base, phone: '', email: '' }),
    (error) => error instanceof CatalogValidationError && error.code === 'contact',
  );
  assert.throws(
    () => buildCatalogReservationPayload({ ...base, email: 'invalido' }),
    (error) => error instanceof CatalogValidationError && error.code === 'email',
  );
  assert.throws(
    () => buildCatalogReservationPayload({ ...base, selection: {} }),
    (error) => error instanceof CatalogValidationError && error.code === 'items',
  );
});

test('consulta publica usa no-store e nao envia credenciais', async () => {
  const catalog = await fetchPublicCatalog({
    config: { apiBaseUrl: 'https://api.sixappback.com' },
    token,
    fetchImpl: async (url, options) => {
      assert.equal(url, `https://api.sixappback.com/public/api/catalogos/${token}`);
      assert.equal(options.method, 'GET');
      assert.equal(options.cache, 'no-store');
      assert.equal(options.credentials, undefined);
      assert.equal(options.headers.Accept, 'application/json');
      return { ok: true, status: 200, json: async () => responseBody };
    },
  });

  assert.equal(catalog.products.length, 2);
});

test('reserva usa POST JSON sem token de autenticacao', async () => {
  const payload = buildCatalogReservationPayload({
    idempotencyKey: '5b3cbf3e-62dc-49d1-b7cb-729501292524',
    name: 'Carlos',
    phone: '47999999999',
    selection: { 'produto-1': 1 },
  });
  const response = await submitCatalogReservation({
    config: { apiBaseUrl: 'https://api.sixappback.com' },
    token,
    payload,
    fetchImpl: async (url, options) => {
      assert.equal(url, `https://api.sixappback.com/public/api/catalogos/${token}/reservas`);
      assert.equal(options.method, 'POST');
      assert.equal(options.credentials, undefined);
      assert.equal(options.headers.Authorization, undefined);
      assert.deepEqual(JSON.parse(options.body), payload);
      return {
        ok: true,
        status: 201,
        json: async () => ({ idReserva: 'reserva-1', status: 'RECEBIDA' }),
      };
    },
  });

  assert.equal(response.idReserva, 'reserva-1');
});

test('erros publicos sao mapeados sem expor corpo do backend', () => {
  assert.equal(catalogErrorKey(new CatalogHttpError(404)), 'error.notFound');
  assert.equal(catalogErrorKey(new CatalogHttpError(429)), 'error.tooManyAttempts');
  assert.equal(catalogErrorKey(new CatalogHttpError(503)), 'error.unavailable');
});

test('dicionario cobre portugues ingles e espanhol com paridade', () => {
  assert.equal(assertPublicDictionaryParity(CATALOG_DICTIONARY), true);
});

test('core do catalogo nao persiste dados pessoais nem credenciais', () => {
  const source = readFileSync('web/site-assets/js/catalog-core.mjs', 'utf8');
  for (const forbidden of [
    'localStorage.setItem',
    'sessionStorage',
    'document.cookie',
    'Authorization:',
    'accessToken',
    'refreshToken',
  ]) {
    assert.equal(source.includes(forbidden), false);
  }
});

test('link gerado usa arquivo direto no localhost e rota amigavel em producao', () => {
  const source = readFileSync(
    'lib/presentation/screens/produto_lista_sub_painel_web.dart',
    'utf8',
  );

  assert.match(source, /'localhost',[\s\S]*'127\.0\.0\.1',[\s\S]*'::1'/);
  assert.match(
    source,
    /resolve\(isLoopback \? '\/catalogo\.html' : '\/catalogo'\)/,
  );
});

test('ponte do flutter run abre o catalogo publico preservando token', () => {
  const source = readFileSync('web/catalogo.html', 'utf8');

  assert.match(source, /new URL\('\/public_catalog\.html'/);
  assert.match(source, /target\.search = window\.location\.search/);
  assert.match(source, /window\.location\.replace\(target\.toString\(\)\)/);
});

test('estado hidden prevalece sobre layouts flex do catalogo', () => {
  const source = readFileSync('web/site-assets/css/catalog.css', 'utf8');

  assert.match(
    source,
    /\.catalog-page \[hidden\]\s*\{\s*display:\s*none\s*!important;/,
  );
});
