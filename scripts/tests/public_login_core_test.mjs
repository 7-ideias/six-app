import assert from 'node:assert/strict';
import test from 'node:test';

import {
  DEFAULT_PUBLIC_API_BASE_URL,
  LOGIN_DICTIONARY,
  PublicLoginConfigError,
  PublicLoginHttpError,
  PublicLoginNetworkError,
  PublicLoginTimeoutError,
  buildLoginRequest,
  createLoginEndpoint,
  loginErrorKeyForStatus,
  normalizeApiBaseUrl,
  performPublicLogin,
  resolvePublicApiConfig,
  resolvePublicLoginRedirect,
  sanitizePublicAppRedirect,
} from '../../web/site-assets/js/login-core.mjs';
import {
  assertPublicDictionaryParity,
} from '../../web/site-assets/js/public-locale.mjs';

test('redirect aceita /app', () => {
  assert.equal(sanitizePublicAppRedirect('/app'), '/app');
  assert.equal(resolvePublicLoginRedirect('', 'https://sixapp.local'), '/app');
});

test('redirect aceita caminho profundo em /app', () => {
  assert.equal(
    sanitizePublicAppRedirect('/app/atendimentos-tecnicos'),
    '/app/atendimentos-tecnicos',
  );
});

test('redirect preserva query string e hash seguros', () => {
  assert.equal(
    sanitizePublicAppRedirect('/app/financeiro?periodo=mes#saldo'),
    '/app/financeiro?periodo=mes#saldo',
  );
  assert.equal(
    resolvePublicLoginRedirect(
      '?redirect=%2Fapp%2Ffinanceiro%3Fperiodo%3Dmes%23saldo',
      'https://sixapp.local',
    ),
    '/app/financeiro?periodo=mes#saldo',
  );
});

test('redirect rejeita URL externa', () => {
  assert.equal(
    sanitizePublicAppRedirect('https://externo.example/app'),
    null,
  );
});

test('redirect rejeita protocol-relative', () => {
  assert.equal(sanitizePublicAppRedirect('//externo.example/app'), null);
});

test('redirect rejeita javascript', () => {
  assert.equal(sanitizePublicAppRedirect('javascript:alert(1)'), null);
});

test('redirect rejeita rotas publicas e admin', () => {
  assert.equal(sanitizePublicAppRedirect('/admin'), null);
  assert.equal(sanitizePublicAppRedirect('/register'), null);
  assert.equal(sanitizePublicAppRedirect('/forgot-password'), null);
  assert.equal(sanitizePublicAppRedirect('/login'), null);
  assert.equal(sanitizePublicAppRedirect('/login/flutter'), null);
});

test('redirect rejeita backslash literal ou codificado', () => {
  assert.equal(sanitizePublicAppRedirect('/app\\admin'), null);
  assert.equal(sanitizePublicAppRedirect('/app%5Cadmin'), null);
});

test('configuracao valida da API normaliza barra final', () => {
  assert.equal(
    normalizeApiBaseUrl('https://api.sixappback.com/'),
    DEFAULT_PUBLIC_API_BASE_URL,
  );
  assert.equal(
    resolvePublicApiConfig({ apiBaseUrl: 'http://localhost:8082/' }).apiBaseUrl,
    'http://localhost:8082',
  );
});

test('configuracao invalida da API falha fechada', () => {
  assert.throws(
    () => resolvePublicApiConfig(null),
    PublicLoginConfigError,
  );
  assert.throws(
    () => normalizeApiBaseUrl('ftp://api.sixappback.com'),
    PublicLoginConfigError,
  );
  assert.throws(
    () => normalizeApiBaseUrl('https://user:pass@api.sixappback.com'),
    PublicLoginConfigError,
  );
  assert.throws(
    () => normalizeApiBaseUrl('http://api.sixappback.com'),
    PublicLoginConfigError,
  );
  assert.throws(
    () => normalizeApiBaseUrl('https://api.sixappback.com?x=1'),
    PublicLoginConfigError,
  );
});

test('montagem do endpoint usa /auth/web/login', () => {
  assert.equal(
    createLoginEndpoint('https://api.sixappback.com/'),
    'https://api.sixappback.com/auth/web/login',
  );
});

test('request usa JSON, credentials include, no-store e preserva senha sem trim', () => {
  const request = buildLoginRequest({
    apiBaseUrl: 'https://api.sixappback.com',
    login: '  usuario@sixapp.com  ',
    senha: '  senha com espacos  ',
  });

  assert.equal(request.endpoint, 'https://api.sixappback.com/auth/web/login');
  assert.equal(request.options.method, 'POST');
  assert.equal(request.options.credentials, 'include');
  assert.equal(request.options.cache, 'no-store');
  assert.equal(request.options.headers['Content-Type'], 'application/json');
  assert.equal(request.options.headers.Accept, 'application/json');
  assert.deepEqual(JSON.parse(request.options.body), {
    login: 'usuario@sixapp.com',
    senha: '  senha com espacos  ',
  });
});

test('mapeamento 401 e 403 usa erro generico de credenciais', () => {
  assert.equal(loginErrorKeyForStatus(401), 'error.invalidCredentials');
  assert.equal(loginErrorKeyForStatus(403), 'error.invalidCredentials');
});

test('mapeamento 429 orienta aguardar', () => {
  assert.equal(loginErrorKeyForStatus(429), 'error.tooManyAttempts');
});

test('mapeamento 5xx indica indisponibilidade temporaria', () => {
  assert.equal(loginErrorKeyForStatus(500), 'error.unavailable');
  assert.equal(loginErrorKeyForStatus(502), 'error.unavailable');
  assert.equal(loginErrorKeyForStatus(503), 'error.unavailable');
  assert.equal(loginErrorKeyForStatus(504), 'error.unavailable');
});

test('performPublicLogin resolve em 2xx sem ler ou persistir corpo', async () => {
  let called = false;
  await performPublicLogin({
    apiBaseUrl: 'https://api.sixappback.com',
    login: 'user',
    senha: 'pass',
    fetchImpl: async (url, options) => {
      called = true;
      assert.equal(url, 'https://api.sixappback.com/auth/web/login');
      assert.equal(options.credentials, 'include');
      return {
        ok: true,
        status: 200,
        json() {
          throw new Error('response body must not be read');
        },
        text() {
          throw new Error('response body must not be read');
        },
      };
    },
  });
  assert.equal(called, true);
});

test('performPublicLogin converte status HTTP em erro tipado', async () => {
  await assert.rejects(
    () => performPublicLogin({
      apiBaseUrl: 'https://api.sixappback.com',
      login: 'user',
      senha: 'pass',
      fetchImpl: async () => ({ ok: false, status: 401 }),
    }),
    PublicLoginHttpError,
  );
});

test('performPublicLogin trata timeout', async () => {
  await assert.rejects(
    () => performPublicLogin({
      apiBaseUrl: 'https://api.sixappback.com',
      login: 'user',
      senha: 'pass',
      timeoutMs: 5,
      fetchImpl: () => new Promise(() => {}),
    }),
    PublicLoginTimeoutError,
  );
});

test('performPublicLogin trata erro de rede', async () => {
  await assert.rejects(
    () => performPublicLogin({
      apiBaseUrl: 'https://api.sixappback.com',
      login: 'user',
      senha: 'pass',
      fetchImpl: async () => {
        throw new Error('network down');
      },
    }),
    PublicLoginNetworkError,
  );
});

test('dicionarios pt/en/es possuem as mesmas chaves', () => {
  assert.equal(assertPublicDictionaryParity(LOGIN_DICTIONARY), true);
});
