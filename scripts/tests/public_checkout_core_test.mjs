import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

import {
  CHECKOUT_DICTIONARY,
  CHECKOUT_SUCCESS_PATH,
  PublicCheckoutHttpError,
  PublicCheckoutNetworkError,
  PublicCheckoutTimeoutError,
  PublicCheckoutValidationError,
  buildCheckoutPayload,
  checkoutErrorKeyForStatus,
  createCheckoutPlansEndpoint,
  extractCheckoutPlans,
  fetchPublicCheckoutMessages,
  getCheckoutPlanFromSearch,
  hasUnsafeCheckoutPriceParam,
  languageTagForCheckout,
  loadPublicCheckoutPlans,
  resolveSelectedCheckoutPlan,
  validateCheckoutPaymentMethod,
} from '../../web/site-assets/js/checkout-core.mjs';
import {
  assertPublicDictionaryParity,
} from '../../web/site-assets/js/public-locale.mjs';

const catalog = {
  locale: 'pt-BR',
  currencyCode: 'BRL',
  planos: [
    {
      codigo: 'STARTER',
      nome: 'Starter',
      descricao: 'Comece a vender hoje.',
      chamadaAcao: 'Começar grátis',
      beneficios: ['Frente de caixa', 'Até 50 produtos'],
      destaque: false,
      preco: { currencyCode: 'BRL', valor: 0, periodicidade: 'GRATUITO' },
      condicoes: { diasTeste: 0, limiteUsuarios: 1, mesesFidelidade: 0, cancelamentoLivre: true },
    },
    {
      codigo: 'PROFESSIONAL',
      nome: 'Professional',
      descricao: 'Para lojas que vivem do balcão e do atendimento.',
      chamadaAcao: 'Assinar',
      beneficios: ['Tudo do Starter', 'Ordens de serviço'],
      destaque: true,
      preco: { currencyCode: 'BRL', valor: 499, periodicidade: 'ANUAL' },
      condicoes: { diasTeste: 7, limiteUsuarios: 3, mesesFidelidade: 0, cancelamentoLivre: true },
    },
    {
      codigo: 'COCKPIT',
      nome: 'Cockpit',
      descricao: 'Para empresas que precisam de um painel executivo.',
      chamadaAcao: 'Falar com vendas',
      beneficios: ['Tudo do Professional', 'Cockpit estratégico'],
      destaque: false,
      preco: { currencyCode: 'BRL', valor: 799, periodicidade: 'ANUAL' },
      condicoes: { diasTeste: 0, limiteUsuarios: null, mesesFidelidade: 12, cancelamentoLivre: false },
    },
  ],
};

test('planos validos preservam codigos e valores do catalogo publico', () => {
  const plans = extractCheckoutPlans(catalog, 'pt');

  assert.deepEqual(plans.map((plan) => plan.id), [
    'STARTER',
    'PROFESSIONAL',
    'COCKPIT',
  ]);
  assert.equal(plans[1].featured, true);
  assert.equal(plans[1].rawAmount, 499);
  assert.match(plans[1].price, /499/);
  assert.deepEqual(plans[0].features, ['Frente de caixa', 'Até 50 produtos']);
  assert.equal(plans[1].conditions.trialDays, 7);
});

test('plano invalido ou ausente cai no featured atual', () => {
  const plans = extractCheckoutPlans(catalog, 'pt');

  assert.equal(
    resolveSelectedCheckoutPlan(plans, 'professional').plan.id,
    'PROFESSIONAL',
  );
  assert.deepEqual(
    resolveSelectedCheckoutPlan(plans, 'Plano inventado'),
    {
      plan: plans[1],
      requestedPlan: 'Plano inventado',
      requestAccepted: false,
      fallbackReason: 'invalid',
    },
  );
  assert.equal(resolveSelectedCheckoutPlan(plans, '').plan.id, 'PROFESSIONAL');
});

test('query usa somente plan e marca price como inseguro', () => {
  assert.equal(
    getCheckoutPlanFromSearch('?plan=PROFESSIONAL&price=1'),
    'PROFESSIONAL',
  );
  assert.equal(hasUnsafeCheckoutPriceParam('?plan=Professional&price=1'), true);
  assert.equal(hasUnsafeCheckoutPriceParam('?plan=Professional'), false);
});

test('payload preserva plano carregado e metodo permitido sem dados sensiveis', () => {
  const plan = extractCheckoutPlans(catalog, 'pt')[1];
  const payload = buildCheckoutPayload({
    plan,
    paymentMethod: 'pix',
    now: () => new Date('2026-08-13T12:00:00.000Z'),
  });

  assert.deepEqual(payload, {
    plan: 'PROFESSIONAL',
    price: plan.price,
    cadence: 'por ano',
    paymentMethod: 'pix',
    createdAt: '2026-08-13T12:00:00.000Z',
  });
  assert.equal(Object.hasOwn(payload, 'cardNumber'), false);
  assert.equal(Object.hasOwn(payload, 'cvv'), false);
});

test('metodo de pagamento invalido falha antes do payload', () => {
  assert.throws(
    () => validateCheckoutPaymentMethod('transferencia'),
    (error) => error instanceof PublicCheckoutValidationError &&
      error.code === 'payment',
  );
});

test('destino final continua local sem redirecionamento de sucesso', () => {
  assert.equal(CHECKOUT_SUCCESS_PATH, null);
});

test('endpoint usa contrato publico de planos, locale e moeda', () => {
  assert.equal(languageTagForCheckout('pt-BR'), 'pt-BR');
  assert.equal(languageTagForCheckout('en-US'), 'en-US');
  assert.equal(languageTagForCheckout('es-ES'), 'es-ES');
  assert.equal(
    createCheckoutPlansEndpoint('https://api.sixappback.com/', 'pt'),
    'https://api.sixappback.com/public/api/planos?locale=pt-BR&currency=BRL',
  );
});

test('request publico usa JSON, no-store e nao envia credenciais', async () => {
  let called = false;
  const result = await fetchPublicCheckoutMessages({
    apiBaseUrl: 'https://api.sixappback.com',
    language: 'pt',
    fetchImpl: async (url, options) => {
      called = true;
      assert.equal(url, 'https://api.sixappback.com/public/api/planos?locale=pt-BR&currency=BRL');
      assert.equal(options.method, 'GET');
      assert.equal(options.cache, 'no-store');
      assert.equal(options.credentials, undefined);
      assert.equal(options.headers.Accept, 'application/json');
      assert.equal(options.headers['Content-Type'], 'application/json');
      return {
        ok: true,
        status: 200,
        json: async () => catalog,
      };
    },
  });

  assert.equal(called, true);
  assert.equal(result, catalog);
});

test('loadPublicCheckoutPlans extrai planos do endpoint publico', async () => {
  const plans = await loadPublicCheckoutPlans({
    config: { apiBaseUrl: 'https://api.sixappback.com' },
    language: 'pt',
    fetchImpl: async () => ({
      ok: true,
      status: 200,
      json: async () => catalog,
    }),
  });

  assert.equal(plans.length, 3);
});

test('erros HTTP sao tipados e mapeados sem corpo bruto', async () => {
  await assert.rejects(
    () => fetchPublicCheckoutMessages({
      apiBaseUrl: 'https://api.sixappback.com',
      language: 'pt',
      fetchImpl: async () => ({
        ok: false,
        status: 404,
        text: async () => 'stack trace',
      }),
    }),
    (error) => error instanceof PublicCheckoutHttpError &&
      error.status === 404,
  );

  assert.equal(checkoutErrorKeyForStatus(400), 'error.invalidData');
  assert.equal(checkoutErrorKeyForStatus(401), 'error.invalidData');
  assert.equal(checkoutErrorKeyForStatus(403), 'error.invalidData');
  assert.equal(checkoutErrorKeyForStatus(404), 'error.invalidData');
  assert.equal(checkoutErrorKeyForStatus(409), 'error.invalidData');
  assert.equal(checkoutErrorKeyForStatus(422), 'error.invalidData');
  assert.equal(checkoutErrorKeyForStatus(429), 'error.tooManyAttempts');
  assert.equal(checkoutErrorKeyForStatus(500), 'error.unavailable');
  assert.equal(checkoutErrorKeyForStatus(502), 'error.unavailable');
  assert.equal(checkoutErrorKeyForStatus(503), 'error.unavailable');
  assert.equal(checkoutErrorKeyForStatus(504), 'error.unavailable');
});

test('timeout e rede viram erros especificos', async () => {
  await assert.rejects(
    () => fetchPublicCheckoutMessages({
      apiBaseUrl: 'https://api.sixappback.com',
      language: 'pt',
      timeoutMs: 5,
      fetchImpl: () => new Promise(() => {}),
    }),
    PublicCheckoutTimeoutError,
  );

  await assert.rejects(
    () => fetchPublicCheckoutMessages({
      apiBaseUrl: 'https://api.sixappback.com',
      language: 'pt',
      fetchImpl: async () => {
        throw new Error('network down');
      },
    }),
    PublicCheckoutNetworkError,
  );
});

test('locale parity cobre pt en es', () => {
  assert.equal(assertPublicDictionaryParity(CHECKOUT_DICTIONARY), true);
});

test('checkout core nao persiste storage sensivel', () => {
  const source = readFileSync('web/site-assets/js/checkout-core.mjs', 'utf8');
  for (const forbidden of [
    'localStorage.setItem',
    'sessionStorage',
    'document.cookie',
    'accessToken',
    'refreshToken',
    'permissoes',
    'cardNumber',
    'cvv',
  ]) {
    assert.equal(source.includes(forbidden), false);
  }
});
