#!/usr/bin/env node

import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { resolvePublicApiBaseUrl } from './lib/resolve_public_api_base_url.mjs';

const DEFAULT_GOOGLE_WEB_CLIENT_ID =
  '841074493827-srvp19o45fh2edon9gq1kgcr1nhrtk5u.apps.googleusercontent.com';

const outputPath = resolve(
  process.argv[2] || 'build/web/site-assets/js/public-config.js',
);

function resolveGoogleWebClientId() {
  const configured = String(process.env.GOOGLE_WEB_CLIENT_ID || '').trim();
  const value = configured || DEFAULT_GOOGLE_WEB_CLIENT_ID;
  if (!/^[0-9]+-[a-z0-9_-]+\.apps\.googleusercontent\.com$/i.test(value)) {
    throw new Error('GOOGLE_WEB_CLIENT_ID invalido.');
  }
  return value;
}

try {
  const apiBaseUrl = resolvePublicApiBaseUrl();
  const googleWebClientId = resolveGoogleWebClientId();
  const content = `/* Generated at build time. Public browser configuration. */
window.SIXAPP_PUBLIC_CONFIG = Object.freeze({
  apiBaseUrl: ${JSON.stringify(apiBaseUrl)},
  googleWebClientId: ${JSON.stringify(googleWebClientId)}
});
`;

  await mkdir(dirname(outputPath), { recursive: true });
  await writeFile(outputPath, content, 'utf8');
  process.stdout.write(`[OK SIX] Public API config generated: ${outputPath}\n`);
} catch (error) {
  process.stderr.write(
    `[ERRO SIX] Configuracao publica da API invalida: ${error.message}\n`,
  );
  process.exit(1);
}
