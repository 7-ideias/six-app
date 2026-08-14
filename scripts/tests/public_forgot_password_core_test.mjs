import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

import {
  FORGOT_PASSWORD_DICTIONARY,
  FORGOT_PASSWORD_SUCCESS_LOGIN_PATH,
  PublicForgotPasswordHttpError,
  PublicForgotPasswordNetworkError,
  PublicForgotPasswordTimeoutError,
  PublicForgotPasswordValidationError,
  buildResetPasswordRequest,
  buildSendCodeRequest,
  buildValidateCodeRequest,
  createResetPasswordEndpoint,
  createSendCodeEndpoint,
  createValidateCodeEndpoint,
  forgotPasswordErrorKeyForStatus,
  forgotPasswordErrorKeyFromError,
  normalizeRecoveryCode,
  normalizeRecoveryEmail,
  normalizeRecoveryPassword,
  performForgotPasswordReset,
  performForgotPasswordSendCode,
  performForgotPasswordValidateCode,
  validateRecoveryCode,
  validateRecoveryEmail,
  validateRecoveryPasswordFields,
} from '../../web/site-assets/js/forgot-password-core.mjs';
import {
  assertPublicDictionaryParity,
} from '../../web/site-assets/js/public-locale.mjs';

test('normalizacao do email preserva somente trim e case digitado', () => {
  assert.equal(
    normalizeRecoveryEmail('  Usuario@SixApp.com  '),
    'Usuario@SixApp.com',
  );
  assert.equal(validateRecoveryEmail(' cliente@six.app '), 'cliente@six.app');
});

test('validacao exige email informado', () => {
  assert.throws(
    () => validateRecoveryEmail('   '),
    (error) => error instanceof PublicForgotPasswordValidationError &&
      error.code === 'email',
  );
});

test('codigo preserva formato numerico de 6 digitos', () => {
  assert.equal(normalizeRecoveryCode('12 3-456'), '123456');
  assert.equal(validateRecoveryCode('123456'), '123456');
  assert.throws(
    () => validateRecoveryCode('12345'),
    (error) => error instanceof PublicForgotPasswordValidationError &&
      error.code === 'codeFormat',
  );
});

test('validacao diferencia codigo vazio e formato invalido', () => {
  assert.throws(
    () => validateRecoveryCode(''),
    (error) => error instanceof PublicForgotPasswordValidationError &&
      error.code === 'codeRequired',
  );
  assert.throws(
    () => validateRecoveryCode('abc'),
    (error) => error instanceof PublicForgotPasswordValidationError &&
      error.code === 'codeFormat',
  );
});

test('nova senha preserva trim do fluxo Flutter atual', () => {
  assert.equal(normalizeRecoveryPassword('  password1  '), 'password1');
  assert.deepEqual(
    validateRecoveryPasswordFields({
      novaSenha: '  password1  ',
      confirmarSenha: 'password1',
    }),
    { novaSenha: 'password1' },
  );
});

test('validacao de senha cobre obrigatoriedade, minimo, maximo e confirmacao', () => {
  assert.throws(
    () => validateRecoveryPasswordFields({
      novaSenha: '',
      confirmarSenha: 'password1',
    }),
    (error) => error instanceof PublicForgotPasswordValidationError &&
      error.code === 'passwordRequired',
  );
  assert.throws(
    () => validateRecoveryPasswordFields({
      novaSenha: '1234567',
      confirmarSenha: '1234567',
    }),
    (error) => error instanceof PublicForgotPasswordValidationError &&
      error.code === 'passwordTooShort',
  );
  assert.throws(
    () => validateRecoveryPasswordFields({
      novaSenha: 'a'.repeat(65),
      confirmarSenha: 'a'.repeat(65),
    }),
    (error) => error instanceof PublicForgotPasswordValidationError &&
      error.code === 'passwordTooLong',
  );
  assert.throws(
    () => validateRecoveryPasswordFields({
      novaSenha: 'password1',
      confirmarSenha: 'password2',
    }),
    (error) => error instanceof PublicForgotPasswordValidationError &&
      error.code === 'passwordMismatch',
  );
});

test('endpoints preservam contrato publico esqueceu-senha', () => {
  assert.equal(
    createSendCodeEndpoint('https://api.sixappback.com/'),
    'https://api.sixappback.com/public/api/esqueceu-senha/enviar-codigo',
  );
  assert.equal(
    createValidateCodeEndpoint('https://api.sixappback.com/'),
    'https://api.sixappback.com/public/api/esqueceu-senha/validar-codigo',
  );
  assert.equal(
    createResetPasswordEndpoint('https://api.sixappback.com/'),
    'https://api.sixappback.com/public/api/esqueceu-senha/redefinir-senha',
  );
});

test('request de envio usa JSON, credentials include e no-store', () => {
  const request = buildSendCodeRequest({
    apiBaseUrl: 'https://api.sixappback.com',
    email: '  cliente@six.app  ',
  });

  assert.equal(
    request.endpoint,
    'https://api.sixappback.com/public/api/esqueceu-senha/enviar-codigo',
  );
  assert.equal(request.options.method, 'POST');
  assert.equal(request.options.credentials, 'include');
  assert.equal(request.options.cache, 'no-store');
  assert.equal(request.options.headers['Content-Type'], 'application/json');
  assert.equal(request.options.headers.Accept, 'application/json');
  assert.deepEqual(JSON.parse(request.options.body), {
    email: 'cliente@six.app',
  });
});

test('request de codigo envia apenas email e codigo', () => {
  const request = buildValidateCodeRequest({
    apiBaseUrl: 'https://api.sixappback.com',
    email: 'cliente@six.app',
    codigo: '123456',
  });

  assert.equal(
    request.endpoint,
    'https://api.sixappback.com/public/api/esqueceu-senha/validar-codigo',
  );
  assert.deepEqual(JSON.parse(request.options.body), {
    email: 'cliente@six.app',
    codigo: '123456',
  });
});

test('request de redefinicao nao envia token nem confirmacao', () => {
  const request = buildResetPasswordRequest({
    apiBaseUrl: 'https://api.sixappback.com',
    email: 'cliente@six.app',
    codigo: '123456',
    novaSenha: '  password1  ',
    confirmarSenha: 'password1',
  });
  const body = JSON.parse(request.options.body);

  assert.equal(
    request.endpoint,
    'https://api.sixappback.com/public/api/esqueceu-senha/redefinir-senha',
  );
  assert.deepEqual(body, {
    email: 'cliente@six.app',
    codigo: '123456',
    novaSenha: 'password1',
  });
  assert.equal(Object.hasOwn(body, 'token'), false);
  assert.equal(Object.hasOwn(body, 'confirmarSenha'), false);
});

test('envio resolve em 204 sem ler corpo remoto', async () => {
  let called = false;
  const result = await performForgotPasswordSendCode({
    apiBaseUrl: 'https://api.sixappback.com',
    email: 'cliente@six.app',
    fetchImpl: async (url, options) => {
      called = true;
      assert.equal(
        url,
        'https://api.sixappback.com/public/api/esqueceu-senha/enviar-codigo',
      );
      assert.equal(options.credentials, 'include');
      assert.deepEqual(JSON.parse(options.body), {
        email: 'cliente@six.app',
      });
      return {
        ok: true,
        status: 204,
        text() {
          throw new Error('response body must not be read');
        },
      };
    },
  });

  assert.equal(called, true);
  assert.deepEqual(result, { neutral: false, status: 204 });
});

test('envio trata 404 e 409 como aceite publico neutro', async () => {
  const notFound = await performForgotPasswordSendCode({
    apiBaseUrl: 'https://api.sixappback.com',
    email: 'ausente@six.app',
    fetchImpl: async () => ({
      ok: false,
      status: 404,
      text: async () => '{"code":"PWD_001"}',
    }),
  });
  const conflict = await performForgotPasswordSendCode({
    apiBaseUrl: 'https://api.sixappback.com',
    email: 'cliente@six.app',
    fetchImpl: async () => ({
      ok: false,
      status: 409,
      text: async () => '{"code":"LOG_001","detail":"interno"}',
    }),
  });

  assert.equal(notFound.neutral, true);
  assert.equal(conflict.neutral, true);
  assert.equal(
    forgotPasswordErrorKeyForStatus(404, 'PWD_001', 'send'),
    'info.instructionsSent',
  );
});

test('validacao de codigo converte status HTTP em erro tipado', async () => {
  await assert.rejects(
    () => performForgotPasswordValidateCode({
      apiBaseUrl: 'https://api.sixappback.com',
      email: 'cliente@six.app',
      codigo: '123456',
      fetchImpl: async () => ({
        ok: false,
        status: 401,
        text: async () => '{"code":"OTP_001"}',
      }),
    }),
    (error) => error instanceof PublicForgotPasswordHttpError &&
      error.status === 401 &&
      error.backendCode === 'OTP_001' &&
      error.action === 'validate',
  );
});

test('redefinicao converte erro de senha invalida', async () => {
  await assert.rejects(
    () => performForgotPasswordReset({
      apiBaseUrl: 'https://api.sixappback.com',
      email: 'cliente@six.app',
      codigo: '123456',
      novaSenha: 'password1',
      confirmarSenha: 'password1',
      fetchImpl: async () => ({
        ok: false,
        status: 422,
        text: async () => '{"code":"PWD_005"}',
      }),
    }),
    (error) => error instanceof PublicForgotPasswordHttpError &&
      error.status === 422 &&
      error.backendCode === 'PWD_005',
  );
});

test('mapeamento cobre codigo invalido, expirado, senha, 429 e 5xx', () => {
  assert.equal(
    forgotPasswordErrorKeyForStatus(401, 'OTP_001', 'validate'),
    'error.codeInvalid',
  );
  assert.equal(
    forgotPasswordErrorKeyForStatus(410, 'PWD_003', 'reset'),
    'error.codeExpired',
  );
  assert.equal(
    forgotPasswordErrorKeyForStatus(422, 'PWD_005', 'reset'),
    'error.passwordInvalid',
  );
  assert.equal(
    forgotPasswordErrorKeyForStatus(429, null, 'send'),
    'error.tooManyAttempts',
  );
  assert.equal(
    forgotPasswordErrorKeyForStatus(503, null, 'send'),
    'error.unavailable',
  );
});

test('erro de validacao vira chave localizada', () => {
  assert.equal(
    forgotPasswordErrorKeyFromError(
      new PublicForgotPasswordValidationError('passwordMismatch'),
    ),
    'error.passwordMismatch',
  );
});

test('corpo remoto inseguro e ignorado', async () => {
  await assert.rejects(
    () => performForgotPasswordValidateCode({
      apiBaseUrl: 'https://api.sixappback.com',
      email: 'cliente@six.app',
      codigo: '123456',
      fetchImpl: async () => ({
        ok: false,
        status: 500,
        text: async () => '{"code":"SECRET_SQL","message":"stack trace"}',
      }),
    }),
    (error) => error instanceof PublicForgotPasswordHttpError &&
      error.status === 500 &&
      error.backendCode === null,
  );
});

test('timeout aborta a chamada', async () => {
  await assert.rejects(
    () => performForgotPasswordSendCode({
      apiBaseUrl: 'https://api.sixappback.com',
      email: 'cliente@six.app',
      timeoutMs: 5,
      fetchImpl: () => new Promise(() => {}),
    }),
    PublicForgotPasswordTimeoutError,
  );
});

test('erro de rede permite retry posterior sem estado compartilhado', async () => {
  let calls = 0;
  await assert.rejects(
    () => performForgotPasswordSendCode({
      apiBaseUrl: 'https://api.sixappback.com',
      email: 'cliente@six.app',
      fetchImpl: async () => {
        calls += 1;
        throw new Error('network down');
      },
    }),
    PublicForgotPasswordNetworkError,
  );

  await performForgotPasswordSendCode({
    apiBaseUrl: 'https://api.sixappback.com',
    email: 'cliente@six.app',
    fetchImpl: async () => {
      calls += 1;
      return { ok: true, status: 204 };
    },
  });
  assert.equal(calls, 2);
});

test('destino final preserva retorno ao login HTML', () => {
  assert.equal(FORGOT_PASSWORD_SUCCESS_LOGIN_PATH, '/login');
});

test('dicionarios pt/en/es possuem as mesmas chaves', () => {
  assert.equal(assertPublicDictionaryParity(FORGOT_PASSWORD_DICTIONARY), true);
});

test('fontes publicas nao persistem codigo, senha ou token', () => {
  const coreSource = readFileSync(
    'web/site-assets/js/forgot-password-core.mjs',
    'utf8',
  );
  const uiSource = readFileSync(
    'web/site-assets/js/forgot-password.js',
    'utf8',
  );
  const combined = `${coreSource}\n${uiSource}`;

  assert.equal(combined.includes('localStorage.setItem'), false);
  assert.equal(combined.includes('sessionStorage'), false);
  assert.equal(combined.includes('document.cookie'), false);
  assert.equal(combined.includes('innerHTML'), false);
});
