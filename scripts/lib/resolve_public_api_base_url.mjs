#!/usr/bin/env node

import { pathToFileURL } from 'node:url';
import {
  DEFAULT_PUBLIC_API_BASE_URL,
  normalizeApiBaseUrl,
} from '../../web/site-assets/js/login-core.mjs';

export function assertNoSecretHint(value) {
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

export function resolvePublicApiBaseUrl(env = process.env) {
  const rawApiBaseUrl =
    env.SIXAPP_PUBLIC_API_BASE_URL || DEFAULT_PUBLIC_API_BASE_URL;
  assertNoSecretHint(rawApiBaseUrl);
  return normalizeApiBaseUrl(rawApiBaseUrl);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    process.stdout.write(`${resolvePublicApiBaseUrl()}\n`);
  } catch (error) {
    process.stderr.write(
      `[ERRO SIX] Configuracao publica da API invalida: ${error.message}\n`,
    );
    process.exit(1);
  }
}
