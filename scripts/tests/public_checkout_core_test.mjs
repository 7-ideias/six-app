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
  createCheckoutI18nEndpoint,
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

const messages = {
  plans: [
    {
      name: 'Starter',
      price: 'R$0',
      cadence: 'para sempre',
      pitch: 'Comece a vender hoje, sem necessidade de cadastro.',
      features: ['Frente de caixa', 'Até 50 produtos'],
      cta: 'Começar grátis',
      featured: false,
    },
    {
      name: 'Professional',
      price: 'R$499',
      cadence: 'por ano',
      pitch: 'Para lojas que vivem do balcão e do atendimento.',
      features: ['Tudo do Starter', 'Ordens de serviço'],
      cta: 'Assinar',
      featured: true,
    },
    {
      name: 'Cockpit',
      price: 'R$799',
      cadence: 'por ano',
      pitch: 'Para empresas que precisam de um painel executivo.',
      features: ['Tudo do Professional', 'Cockpit estratégico'],
      cta: 'Falar com vendas',
      featured: false,
    },
  ],
};

test('planos validos preservam ids reais do i18n publico', () => {
  const plans = extractCheckoutPlans(messages);

  assert.deepEqual(plans.map((plan) => plan.id), [
    'Starter',
    'Professional',
    'Cockpit',
  ]);
  assert.equal(plans[1].featured, true);
  assert.equal(plans[1].price, 'R$499');
  assert.deepEqual(plans[0].features, ['Frente de caixa', 'Até 50 produtos']);
});

test('plano invalido ou ausente cai no featured atual', () => {
  const plans = extractCheckoutPlans(messages);

  assert.equal(
    resolveSelectedCheckoutPlan(plans, 'Professional').plan.id,
    'Professional',
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
  assert.equal(resolveSelectedCheckoutPlan(plans, '').plan.id, 'Professional');
});

test('query usa somente plan e marca price como inseguro', () => {
  assert.equal(
    getCheckoutPlanFromSearch('?plan=Professional&price=1'),
    'Professional',
  );
  assert.equal(hasUnsafeCheckoutPriceParam('?plan=Professional&price=1'), true);
  assert.equal(hasUnsafeCheckoutPriceParam('?plan=Professional'), false);
});

test('payload preserva plano carregado e metodo permitido sem dados sensiveis', () => {
  const plan = extractCheckoutPlans(messages)[1];
  const payload = buildCheckoutPayload({
    plan,
    paymentMethod: 'pix',
    now: () => new Date('2026-08-13T12:00:00.000Z'),
  });

  assert.deepEqual(payload, {
    plan: 'Professional',
    price: 'R$499',
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

test('endpoint usa contrato publico de i18n por idioma', () => {
  assert.equal(languageTagForCheckout('pt-BR'), 'pt-BR');
  assert.equal(languageTagForCheckout('en-US'), 'en-US');
  assert.equal(languageTagForCheckout('es-ES'), 'es-ES');
  assert.equal(
    createCheckoutI18nEndpoint('https://api.sixappback.com/', 'pt'),
    'https://api.sixappback.com/public/api/i18n/pt-BR',
  );
});

test('request publico usa JSON, no-store e nao envia credenciais', async () => {
  let called = false;
  const result = await fetchPublicCheckoutMessages({
    apiBaseUrl: 'https://api.sixappback.com',
    language: 'pt',
    fetchImpl: async (url, options) => {
      called = true;
      assert.equal(url, 'https://api.sixappback.com/public/api/i18n/pt-BR');
      assert.equal(options.method, 'GET');
      assert.equal(options.cache, 'no-store');
      assert.equal(options.credentials, undefined);
      assert.equal(options.headers.Accept, 'application/json');
      assert.equal(options.headers['Content-Type'], 'application/json');
      return {
        ok: true,
        status: 200,
        json: async () => ({ messages }),
      };
    },
  });

  assert.equal(called, true);
  assert.equal(result, messages);
});

test('loadPublicCheckoutPlans extrai planos do endpoint publico', async () => {
  const plans = await loadPublicCheckoutPlans({
    config: { apiBaseUrl: 'https://api.sixappback.com' },
    language: 'pt',
    fetchImpl: async () => ({
      ok: true,
      status: 200,
      json: async () => ({ messages }),
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
