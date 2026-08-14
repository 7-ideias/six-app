#!/usr/bin/env node

import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import {
  DEFAULT_PUBLIC_API_BASE_URL,
  normalizeApiBaseUrl,
} from '../web/site-assets/js/login-core.mjs';

const outputPath = resolve(
  process.argv[2] || 'build/web/site-assets/js/public-config.js',
);
const rawApiBaseUrl =
  process.env.SIXAPP_PUBLIC_API_BASE_URL || DEFAULT_PUBLIC_API_BASE_URL;

function assertNoSecretHint(value) {
  const normalized = String(value || '').toLowerCase();
  const forbidden = [
    'client_secret',
    'access_token',
    'refresh_token',
    'bearer ',
    'password=',
    'senha=',
    'token=',
    'secret=',
  ];
  const match = forbidden.find((pattern) => normalized.includes(pattern));
  if (match) {
    throw new Error(`Public API base URL contains forbidden secret-like content: ${match}`);
  }
}

try {
  assertNoSecretHint(rawApiBaseUrl);
  const apiBaseUrl = normalizeApiBaseUrl(rawApiBaseUrl);
  const content = `/* Generated at build time. Public browser configuration. */
window.SIXAPP_PUBLIC_CONFIG = Object.freeze({
  apiBaseUrl: ${JSON.stringify(apiBaseUrl)}
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
