import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import {
  assertNoSecretHint,
  resolvePublicApiBaseUrl,
} from '../lib/resolve_public_api_base_url.mjs';

test('resolve API publica local para HTML e Flutter Web', () => {
  assert.equal(
    resolvePublicApiBaseUrl({
      SIXAPP_PUBLIC_API_BASE_URL: 'http://localhost:9999/',
    }),
    'http://localhost:9999',
  );
});

test('preserva fallback publico de producao sem variavel local', () => {
  assert.equal(resolvePublicApiBaseUrl({}), 'https://api.sixappback.com');
});

test('rejeita indicios de segredo na URL publica', () => {
  assert.throws(
    () => assertNoSecretHint('https://api.sixappback.com?token=abc'),
    /forbidden secret-like content/,
  );
});

test('script composto usa um API_URL unico no public-config e no dart-define', () => {
  const source = readFileSync('scripts/build_web_with_public_home.sh', 'utf8');

  assert.match(
    source,
    /API_URL="\$\("\$NODE_BIN" scripts\/lib\/resolve_public_api_base_url\.mjs\)"/,
  );
  assert.match(source, /export SIXAPP_PUBLIC_API_BASE_URL="\$API_URL"/);
  assert.match(source, /--dart-define="API_BASE_URL=\$API_URL"/);
  assert.doesNotMatch(source, /FLUTTER_API_URL|HTML_API_URL/);
});
