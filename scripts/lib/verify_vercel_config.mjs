import { readFileSync } from 'node:fs';

const configPath = process.argv[2] ?? 'vercel.json';

function fail(message) {
  console.error(`[ERRO SIX] ${message}`);
  process.exit(1);
}

function requireCondition(description, condition) {
  if (!condition) {
    fail(`vercel.json invalido para: ${description}`);
  }
}

function includesEntry(entries, source, destination) {
  return Array.isArray(entries) && entries.some(
    (entry) => entry?.source === source && entry?.destination === destination,
  );
}

function requireRewrite(source, destination) {
  requireCondition(
    `Rewrite ausente: ${source} -> ${destination}`,
    includesEntry(config.rewrites, source, destination),
  );
}

function requireRedirect(source, destination) {
  requireCondition(
    `${source} redireciona para ${destination}`,
    includesEntry(config.redirects, source, destination),
  );
}

function headerEntry(source, key, value) {
  return Array.isArray(config.headers) && config.headers.some(
    (entry) => entry?.source === source && Array.isArray(entry.headers) && entry.headers.some(
      (header) => header?.key === key && header?.value === value,
    ),
  );
}

function requireHeader(source, key, value) {
  requireCondition(
    `${key} restrito ao ${source}`,
    headerEntry(source, key, value),
  );
}

let config;

try {
  config = JSON.parse(readFileSync(configPath, 'utf8'));
} catch {
  fail('vercel.json nao e JSON valido');
}

requireCondition(
  'buildCommand usa scripts/build_web_with_public_home.sh',
  typeof config.buildCommand === 'string' &&
    config.buildCommand.includes('scripts/build_web_with_public_home.sh'),
);
requireCondition(
  'outputDirectory build/web',
  config.outputDirectory === 'build/web',
);

requireRedirect('/home', '/');

requireRewrite('/atendimento/status', 'https://api.sixappback.com/atendimento/status');
requireRewrite('/atendimento/status/assinatura', 'https://api.sixappback.com/atendimento/status/assinatura');
requireRewrite('/public/status/:path*', 'https://api.sixappback.com/public/status/:path*');
requireRewrite('/login', '/login.html');
requireRewrite('/login/flutter', '/flutter.html');
requireRewrite('/register', '/register.html');
requireRewrite('/register/flutter', '/flutter.html');
requireRewrite('/forgot-password', '/forgot-password.html');
requireRewrite('/forgot-password/flutter', '/flutter.html');
requireRewrite('/onboarding', '/onboarding.html');
requireRewrite('/onboarding/flutter', '/flutter.html');
requireRewrite('/checkout', '/checkout.html');
requireRewrite('/checkout/flutter', '/flutter.html');
requireRewrite('/app', '/flutter.html');
requireRewrite('/app/:path*', '/flutter.html');
requireRewrite('/admin', '/flutter.html');
requireRewrite('/admin/:path*', '/flutter.html');
requireRewrite('/atendimento/assinatura', '/flutter.html');
requireRewrite('/ordem-servico', '/flutter.html');
requireRewrite('/ordem-servico/:path*', '/flutter.html');
requireRewrite('/cliente/auto-cadastro', '/flutter.html');
requireRewrite('/cliente/auto-cadastro/:path*', '/flutter.html');
requireRewrite('/colaborador/convites/:path*', '/flutter.html');

if (Array.isArray(config.rewrites) && config.rewrites.some((entry) => entry?.source === '/login/:path*')) {
  fail('Rewrite proibido encontrado: /login/:path*');
}

if (Array.isArray(config.rewrites) && config.rewrites.some((entry) => (
  entry?.destination === '/index.html' &&
  (
    String(entry?.source ?? '').includes('((?!') ||
    String(entry?.source ?? '').includes(':path*') ||
    entry?.source === '/(.*)'
  )
))) {
  fail('Catch-all proibido encontrado enviando rotas genericas para /index.html');
}

const sensitiveSources = [
  '/login',
  '/login.html',
  '/register',
  '/register.html',
  '/forgot-password',
  '/forgot-password.html',
  '/onboarding',
  '/onboarding.html',
  '/checkout',
  '/checkout.html',
];

for (const source of sensitiveSources) {
  requireHeader(source, 'Cache-Control', 'no-store, max-age=0');
  requireHeader(source, 'X-Content-Type-Options', 'nosniff');
  requireHeader(source, 'Referrer-Policy', 'strict-origin-when-cross-origin');
  requireHeader(source, 'X-Frame-Options', 'DENY');
}

if (Array.isArray(config.headers) && config.headers.some((entry) => (
  !sensitiveSources.includes(entry?.source) &&
  Array.isArray(entry?.headers) &&
  entry.headers.some((header) => (
    (header?.key === 'Cache-Control' && header?.value === 'no-store, max-age=0') ||
    header?.key === 'X-Frame-Options'
  ))
))) {
  fail('Headers de seguranca/cache publicos aplicados fora de /login, /register, /forgot-password, /onboarding e /checkout');
}
