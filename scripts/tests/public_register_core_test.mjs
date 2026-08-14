import assert from 'node:assert/strict';
import test from 'node:test';

import {
  REGISTER_DICTIONARY,
  REGISTER_SUCCESS_LOGIN_PATH,
  PublicRegisterHttpError,
  PublicRegisterNetworkError,
  PublicRegisterTimeoutError,
  PublicRegisterValidationError,
  buildRegisterPayload,
  buildRegisterRequest,
  createRegisterEndpoint,
  normalizeRegisterLogin,
  performPublicRegister,
  registerErrorKeyForStatus,
  registerErrorKeyFromError,
  validateRegisterFields,
} from '../../web/site-assets/js/register-core.mjs';
import {
  assertPublicDictionaryParity,
} from '../../web/site-assets/js/public-locale.mjs';

test('normalizacao preserva somente trim do login', () => {
  assert.equal(normalizeRegisterLogin('  Usuario@SixApp.com  '), 'Usuario@SixApp.com');
});

test('validacao exige aceite dos termos', () => {
  assert.throws(
    () => validateRegisterFields({
      login: 'usuario',
      senha: '12345678',
      confirmarSenha: '12345678',
      aceitaTermos: false,
    }),
    (error) => error instanceof PublicRegisterValidationError &&
      error.code === 'terms',
  );
});

test('validacao exige todos os campos', () => {
  assert.throws(
    () => validateRegisterFields({
      login: 'usuario',
      senha: '',
      confirmarSenha: '12345678',
      aceitaTermos: true,
    }),
    (error) => error instanceof PublicRegisterValidationError &&
      error.code === 'allFields',
  );
});

test('validacao exige senha com minimo de 8 caracteres', () => {
  assert.throws(
    () => validateRegisterFields({
      login: 'usuario',
      senha: '1234567',
      confirmarSenha: '1234567',
      aceitaTermos: true,
    }),
    (error) => error instanceof PublicRegisterValidationError &&
      error.code === 'passwordTooShort',
  );
});

test('validacao exige senha e confirmacao iguais', () => {
  assert.throws(
    () => validateRegisterFields({
      login: 'usuario',
      senha: '12345678',
      confirmarSenha: '87654321',
      aceitaTermos: true,
    }),
    (error) => error instanceof PublicRegisterValidationError &&
      error.code === 'passwordMismatch',
  );
});

test('validacao preserva senha sem trim', () => {
  assert.deepEqual(
    validateRegisterFields({
      login: '  usuario  ',
      senha: '  senha com espacos  ',
      confirmarSenha: '  senha com espacos  ',
      aceitaTermos: true,
    }),
    {
      login: 'usuario',
      senha: '  senha com espacos  ',
    },
  );
});

test('payload usa contrato simplificado de nova empresa', () => {
  assert.deepEqual(
    buildRegisterPayload({
      login: 'usuario',
      senha: 'senha-segura',
    }),
    {
      login: 'usuario',
      username: 'usuario',
      senha: 'senha-segura',
      senhaInicial: 'senha-segura',
      permissoes: ['ADMINISTRADOR'],
    },
  );
});

test('payload inclui email apenas quando login parece email', () => {
  assert.deepEqual(
    buildRegisterPayload({
      login: 'user@sixapp.com',
      senha: 'senha-segura',
    }),
    {
      login: 'user@sixapp.com',
      username: 'user@sixapp.com',
      senha: 'senha-segura',
      senhaInicial: 'senha-segura',
      permissoes: ['ADMINISTRADOR'],
      email: 'user@sixapp.com',
    },
  );
});

test('montagem do endpoint usa /public/api/login/nova-empresa', () => {
  assert.equal(
    createRegisterEndpoint('https://api.sixappback.com/'),
    'https://api.sixappback.com/public/api/login/nova-empresa',
  );
});

test('request usa JSON, credentials include e no-store', () => {
  const request = buildRegisterRequest({
    apiBaseUrl: 'https://api.sixappback.com',
    login: '  usuario@sixapp.com  ',
    senha: '  senha com espacos  ',
    confirmarSenha: '  senha com espacos  ',
    aceitaTermos: true,
  });

  assert.equal(request.endpoint, 'https://api.sixappback.com/public/api/login/nova-empresa');
  assert.equal(request.options.method, 'POST');
  assert.equal(request.options.credentials, 'include');
  assert.equal(request.options.cache, 'no-store');
  assert.equal(request.options.headers['Content-Type'], 'application/json');
  assert.equal(request.options.headers.Accept, 'application/json');
  assert.deepEqual(JSON.parse(request.options.body), {
    login: 'usuario@sixapp.com',
    username: 'usuario@sixapp.com',
    senha: '  senha com espacos  ',
    senhaInicial: '  senha com espacos  ',
    permissoes: ['ADMINISTRADOR'],
    email: 'usuario@sixapp.com',
  });
});

test('mapeamento 400 e 422 usa dados invalidos', () => {
  assert.equal(registerErrorKeyForStatus(400), 'error.invalidData');
  assert.equal(registerErrorKeyForStatus(422), 'error.invalidData');
});

test('mapeamento 409 usa conflito de conta existente', () => {
  assert.equal(registerErrorKeyForStatus(409), 'error.accountExists');
});

test('mapeamento 429 orienta aguardar', () => {
  assert.equal(registerErrorKeyForStatus(429), 'error.tooManyAttempts');
});

test('mapeamento 5xx indica indisponibilidade temporaria', () => {
  assert.equal(registerErrorKeyForStatus(500), 'error.unavailable');
  assert.equal(registerErrorKeyForStatus(502), 'error.unavailable');
  assert.equal(registerErrorKeyForStatus(503), 'error.unavailable');
  assert.equal(registerErrorKeyForStatus(504), 'error.unavailable');
});

test('mapeamento OTP preserva codigos publicos conhecidos', () => {
  assert.equal(registerErrorKeyForStatus(401, 'OTP_001'), 'error.invalidOtp');
  assert.equal(registerErrorKeyForStatus(502, 'OTP_002'), 'error.otpEmailUnavailable');
  assert.equal(registerErrorKeyForStatus(403, 'OTP_003'), 'error.emailNotVerified');
});

test('erro de validacao vira chave localizada', () => {
  assert.equal(
    registerErrorKeyFromError(new PublicRegisterValidationError('passwordMismatch')),
    'error.passwordsNotEqual',
  );
});

test('performPublicRegister resolve em 2xx sem ler ou persistir corpo', async () => {
  let called = false;
  await performPublicRegister({
    apiBaseUrl: 'https://api.sixappback.com',
    login: 'user',
    senha: 'password1',
    confirmarSenha: 'password1',
    aceitaTermos: true,
    fetchImpl: async (url, options) => {
      called = true;
      assert.equal(url, 'https://api.sixappback.com/public/api/login/nova-empresa');
      assert.equal(options.credentials, 'include');
      assert.deepEqual(JSON.parse(options.body), {
        login: 'user',
        username: 'user',
        senha: 'password1',
        senhaInicial: 'password1',
        permissoes: ['ADMINISTRADOR'],
      });
      return {
        ok: true,
        status: 201,
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

test('performPublicRegister converte status HTTP em erro tipado', async () => {
  await assert.rejects(
    () => performPublicRegister({
      apiBaseUrl: 'https://api.sixappback.com',
      login: 'user',
      senha: 'password1',
      confirmarSenha: 'password1',
      aceitaTermos: true,
      fetchImpl: async () => ({
        ok: false,
        status: 409,
        text: async () => '{"code":"LOG_001"}',
      }),
    }),
    (error) => error instanceof PublicRegisterHttpError &&
      error.status === 409 &&
      error.backendCode === 'LOG_001',
  );
});

test('performPublicRegister ignora corpo remoto inseguro', async () => {
  await assert.rejects(
    () => performPublicRegister({
      apiBaseUrl: 'https://api.sixappback.com',
      login: 'user',
      senha: 'password1',
      confirmarSenha: 'password1',
      aceitaTermos: true,
      fetchImpl: async () => ({
        ok: false,
        status: 500,
        text: async () => '{"code":"SECRET_SQL","message":"stack trace"}',
      }),
    }),
    (error) => error instanceof PublicRegisterHttpError &&
      error.status === 500 &&
      error.backendCode === null,
  );
});

test('performPublicRegister trata timeout', async () => {
  await assert.rejects(
    () => performPublicRegister({
      apiBaseUrl: 'https://api.sixappback.com',
      login: 'user',
      senha: 'password1',
      confirmarSenha: 'password1',
      aceitaTermos: true,
      timeoutMs: 5,
      fetchImpl: () => new Promise(() => {}),
    }),
    PublicRegisterTimeoutError,
  );
});

test('performPublicRegister trata erro de rede', async () => {
  await assert.rejects(
    () => performPublicRegister({
      apiBaseUrl: 'https://api.sixappback.com',
      login: 'user',
      senha: 'password1',
      confirmarSenha: 'password1',
      aceitaTermos: true,
      fetchImpl: async () => {
        throw new Error('network down');
      },
    }),
    PublicRegisterNetworkError,
  );
});

test('sucesso do cadastro mantem redirect final sem autenticar', () => {
  assert.equal(REGISTER_SUCCESS_LOGIN_PATH, '/login');
});

test('dicionarios pt/en/es possuem as mesmas chaves', () => {
  assert.equal(assertPublicDictionaryParity(REGISTER_DICTIONARY), true);
});
