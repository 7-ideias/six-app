#!/usr/bin/env node

import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { resolvePublicApiBaseUrl } from './lib/resolve_public_api_base_url.mjs';

const outputPath = resolve(
  process.argv[2] || 'build/web/site-assets/js/public-config.js',
);

try {
  const apiBaseUrl = resolvePublicApiBaseUrl();
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
