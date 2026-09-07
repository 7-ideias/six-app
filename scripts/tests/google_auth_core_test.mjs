import assert from 'node:assert/strict';
import test from 'node:test';

import {
  PublicGoogleAuthError,
  googleBackendLanguage,
  googleErrorKey,
  performGoogleLink,
  performGoogleLogin,
  performGoogleRegistration,
  resolveGoogleWebClientId,
} from '../../web/site-assets/js/google-auth-core.mjs';

const clientId = '841074493827-srvp19o45fh2edon9gq1kgcr1nhrtk5u.apps.googleusercontent.com';

function okFetch(calls) {
  return async (url, options) => {
    calls.push({ url, options });
    return {
      ok: true,
      status: 200,
      async text() { return ''; },
    };
  };
}

test('resolve client id aceita o cliente web de producao', () => {
  assert.equal(resolveGoogleWebClientId({ googleWebClientId: clientId }), clientId);
  assert.throws(() => resolveGoogleWebClientId({ googleWebClientId: 'invalido' }));
});

test('login Google Web envia access token e nao depende de idToken', async () => {
  const calls = [];
  await performGoogleLogin({
    apiBaseUrl: 'https://api.sixappback.com',
    accessToken: 'google-access-token',
    idioma: 'pt',
    fetchImpl: okFetch(calls),
  });

  assert.equal(calls[0].url, 'https://api.sixappback.com/auth/web/google');
  assert.equal(calls[0].options.credentials, 'include');
  assert.deepEqual(JSON.parse(calls[0].options.body), {
    idToken: null,
    accessToken: 'google-access-token',
    fluxo: 'LOGIN',
    aceiteTermos: false,
    idioma: 'pt-BR',
  });
});

test('cadastro Google envia access token, termos e fluxo CADASTRO sem senha', async () => {
  const calls = [];
  await performGoogleRegistration({
    apiBaseUrl: 'https://api.sixappback.com',
    accessToken: 'google-access-token',
    aceiteTermos: true,
    idioma: 'es',
    fetchImpl: okFetch(calls),
  });

  assert.deepEqual(JSON.parse(calls[0].options.body), {
    idToken: null,
    accessToken: 'google-access-token',
    fluxo: 'CADASTRO',
    aceiteTermos: true,
    idioma: 'es-ES',
  });
  assert.equal('senha' in JSON.parse(calls[0].options.body), false);
});

test('vinculo seguro reutiliza access token e envia senha somente ao endpoint link', async () => {
  const calls = [];
  await performGoogleLink({
    apiBaseUrl: 'https://api.sixappback.com',
    accessToken: 'google-access-token',
    senha: 'senha-atual',
    fluxo: 'CADASTRO',
    aceiteTermos: true,
    idioma: 'en',
    fetchImpl: okFetch(calls),
  });

  assert.equal(calls[0].url, 'https://api.sixappback.com/auth/web/google/link');
  assert.deepEqual(JSON.parse(calls[0].options.body), {
    idToken: null,
    accessToken: 'google-access-token',
    fluxo: 'CADASTRO',
    aceiteTermos: true,
    idioma: 'en-US',
    senha: 'senha-atual',
  });
});

test('Google Web rejeita chamada sem access token antes de tocar backend', async () => {
  await assert.rejects(
    performGoogleLogin({
      apiBaseUrl: 'https://api.sixappback.com',
      accessToken: '',
      fetchImpl: okFetch([]),
    }),
    (error) => error instanceof PublicGoogleAuthError && error.code === 'missingCredential',
  );
});

test('erros de backend distinguem vinculo, cadastro e credencial', () => {
  assert.equal(
    googleErrorKey(new PublicGoogleAuthError('x', { status: 409 }), 'login'),
    'google.link.required',
  );
  assert.equal(
    googleErrorKey(new PublicGoogleAuthError('x', { status: 404 }), 'login'),
    'google.error.registrationRequired',
  );
  assert.equal(
    googleErrorKey(new PublicGoogleAuthError('x', { status: 401 }), 'register'),
    'google.error.invalidCredential',
  );
  assert.equal(
    googleErrorKey(new PublicGoogleAuthError('x', { status: 502 }), 'login'),
    'google.error.unavailable',
  );
});

test('idiomas publicos viram tags aceitas pelo backend', () => {
  assert.equal(googleBackendLanguage('pt'), 'pt-BR');
  assert.equal(googleBackendLanguage('en'), 'en-US');
  assert.equal(googleBackendLanguage('es'), 'es-ES');
});
