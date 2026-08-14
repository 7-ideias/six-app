export const DEFAULT_PUBLIC_API_BASE_URL = 'https://api.sixappback.com';
export const LOGIN_TIMEOUT_MS = 15000;

export const LOGIN_DICTIONARY = Object.freeze({
  pt: Object.freeze({
    title: 'SixApp - Entrar',
    description: 'Acesse sua operação no SixApp para acompanhar vendas, atendimentos, clientes, equipe e financeiro.',
    ogTitle: 'SixApp - Entrar',
    ogDescription: 'Login seguro para acessar sua operação no SixApp.',
    twitterTitle: 'SixApp - Entrar',
    twitterDescription: 'Acesse vendas, atendimentos, clientes, equipe e financeiro no SixApp.',
    'access.skip': 'Ir para o formulário de login',
    'brand.aria': 'SixApp',
    'nav.home': 'Voltar para a página inicial',
    'language.aria': 'Selecionar idioma',
    'context.eyebrow': 'Acesso seguro',
    'context.title': 'Acesse sua operação',
    'context.body': 'Entre para acompanhar vendas, atendimentos, clientes, equipe e financeiro em um só lugar.',
    'context.item.one': 'Handoff completo para o app autenticado.',
    'context.item.two': 'Sessão validada pelo backend e pelo Keycloak.',
    'context.item.three': 'Dados sensíveis protegidos por cookie HttpOnly.',
    'form.title': 'Entrar no SixApp',
    'form.subtitle': 'Use seu login ou e-mail cadastrado.',
    'form.login.label': 'Login ou e-mail',
    'form.login.placeholder': 'Informe seu login de acesso',
    'form.password.label': 'Senha',
    'form.password.placeholder': 'Digite sua senha',
    'form.password.show': 'Mostrar',
    'form.password.hide': 'Ocultar',
    'form.password.showAria': 'Mostrar senha',
    'form.password.hideAria': 'Ocultar senha',
    'form.forgot': 'Esqueci minha senha',
    'form.submit': 'Entrar',
    'form.loading': 'Entrando...',
    'form.create.prompt': 'Ainda não tem conta?',
    'form.create.link': 'Criar conta',
    'form.compatibility': 'Entrar pela versão compatível',
    'noscript.message': 'Para entrar por esta página, ative o JavaScript. Você também pode acessar a versão compatível.',
    'noscript.link': 'Entrar pela versão compatível',
    'error.requiredLogin': 'Informe seu login ou e-mail.',
    'error.requiredPassword': 'Informe sua senha.',
    'error.config': 'Não foi possível preparar o acesso seguro. Tente novamente mais tarde.',
    'error.invalidData': 'Revise os dados informados e tente novamente.',
    'error.invalidCredentials': 'Não foi possível entrar com os dados informados.',
    'error.tooManyAttempts': 'Muitas tentativas em sequência. Aguarde alguns minutos e tente novamente.',
    'error.unavailable': 'Serviço temporariamente indisponível. Tente novamente em instantes.',
    'error.timeout': 'A conexão demorou mais do que o esperado. Tente novamente.',
    'error.network': 'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.',
    'error.unexpected': 'Não foi possível entrar agora. Tente novamente em instantes.',
    'error.pending': 'Aguarde a tentativa atual terminar.'
  }),
  en: Object.freeze({
    title: 'SixApp - Sign In',
    description: 'Access your SixApp operation to follow sales, service, customers, team and finance.',
    ogTitle: 'SixApp - Sign In',
    ogDescription: 'Secure sign-in to access your SixApp operation.',
    twitterTitle: 'SixApp - Sign In',
    twitterDescription: 'Access sales, service, customers, team and finance in SixApp.',
    'access.skip': 'Skip to the sign-in form',
    'brand.aria': 'SixApp',
    'nav.home': 'Back to the home page',
    'language.aria': 'Select language',
    'context.eyebrow': 'Secure access',
    'context.title': 'Access your operation',
    'context.body': 'Sign in to follow sales, service, customers, team and finance in one place.',
    'context.item.one': 'Full handoff to the authenticated app.',
    'context.item.two': 'Session validated by the backend and Keycloak.',
    'context.item.three': 'Sensitive data protected by an HttpOnly cookie.',
    'form.title': 'Sign in to SixApp',
    'form.subtitle': 'Use your registered login or email.',
    'form.login.label': 'Login or email',
    'form.login.placeholder': 'Enter your access login',
    'form.password.label': 'Password',
    'form.password.placeholder': 'Enter your password',
    'form.password.show': 'Show',
    'form.password.hide': 'Hide',
    'form.password.showAria': 'Show password',
    'form.password.hideAria': 'Hide password',
    'form.forgot': 'Forgot password',
    'form.submit': 'Sign in',
    'form.loading': 'Signing in...',
    'form.create.prompt': 'Do not have an account yet?',
    'form.create.link': 'Create account',
    'form.compatibility': 'Use the compatible version',
    'noscript.message': 'Enable JavaScript to sign in from this page. You can also use the compatible version.',
    'noscript.link': 'Use the compatible version',
    'error.requiredLogin': 'Enter your login or email.',
    'error.requiredPassword': 'Enter your password.',
    'error.config': 'Could not prepare secure access. Try again later.',
    'error.invalidData': 'Review the information and try again.',
    'error.invalidCredentials': 'Could not sign in with the provided credentials.',
    'error.tooManyAttempts': 'Too many attempts in a row. Wait a few minutes and try again.',
    'error.unavailable': 'Service temporarily unavailable. Try again shortly.',
    'error.timeout': 'The connection took longer than expected. Try again.',
    'error.network': 'Could not connect to the server. Check your connection and try again.',
    'error.unexpected': 'Could not sign in right now. Try again shortly.',
    'error.pending': 'Wait for the current attempt to finish.'
  }),
  es: Object.freeze({
    title: 'SixApp - Entrar',
    description: 'Accede a tu operación en SixApp para acompañar ventas, atención, clientes, equipo y finanzas.',
    ogTitle: 'SixApp - Entrar',
    ogDescription: 'Login seguro para acceder a tu operación en SixApp.',
    twitterTitle: 'SixApp - Entrar',
    twitterDescription: 'Accede a ventas, atención, clientes, equipo y finanzas en SixApp.',
    'access.skip': 'Ir al formulario de acceso',
    'brand.aria': 'SixApp',
    'nav.home': 'Volver a la página inicial',
    'language.aria': 'Seleccionar idioma',
    'context.eyebrow': 'Acceso seguro',
    'context.title': 'Accede a tu operación',
    'context.body': 'Entra para acompañar ventas, atención, clientes, equipo y finanzas en un solo lugar.',
    'context.item.one': 'Handoff completo hacia la app autenticada.',
    'context.item.two': 'Sesión validada por el backend y Keycloak.',
    'context.item.three': 'Datos sensibles protegidos por cookie HttpOnly.',
    'form.title': 'Entrar en SixApp',
    'form.subtitle': 'Usa tu login o e-mail registrado.',
    'form.login.label': 'Login o e-mail',
    'form.login.placeholder': 'Informa tu login de acceso',
    'form.password.label': 'Contraseña',
    'form.password.placeholder': 'Escribe tu contraseña',
    'form.password.show': 'Mostrar',
    'form.password.hide': 'Ocultar',
    'form.password.showAria': 'Mostrar contraseña',
    'form.password.hideAria': 'Ocultar contraseña',
    'form.forgot': 'Olvidé mi contraseña',
    'form.submit': 'Entrar',
    'form.loading': 'Entrando...',
    'form.create.prompt': '¿Aún no tienes cuenta?',
    'form.create.link': 'Crear cuenta',
    'form.compatibility': 'Entrar por la versión compatible',
    'noscript.message': 'Para entrar por esta página, activa JavaScript. También puedes acceder a la versión compatible.',
    'noscript.link': 'Entrar por la versión compatible',
    'error.requiredLogin': 'Informa tu login o e-mail.',
    'error.requiredPassword': 'Informa tu contraseña.',
    'error.config': 'No fue posible preparar el acceso seguro. Intenta nuevamente más tarde.',
    'error.invalidData': 'Revisa los datos informados e intenta nuevamente.',
    'error.invalidCredentials': 'No fue posible entrar con los datos informados.',
    'error.tooManyAttempts': 'Muchas tentativas en secuencia. Espera algunos minutos e intenta nuevamente.',
    'error.unavailable': 'Servicio temporalmente indisponible. Intenta nuevamente en instantes.',
    'error.timeout': 'La conexión tardó más de lo esperado. Intenta nuevamente.',
    'error.network': 'No fue posible conectar al servidor. Verifica tu conexión e intenta nuevamente.',
    'error.unexpected': 'No fue posible entrar ahora. Intenta nuevamente en instantes.',
    'error.pending': 'Espera a que termine la tentativa actual.'
  })
});

export class PublicLoginConfigError extends Error {
  constructor(message) {
    super(message);
    this.name = 'PublicLoginConfigError';
  }
}

export class PublicLoginValidationError extends Error {
  constructor(code) {
    super(code);
    this.name = 'PublicLoginValidationError';
    this.code = code;
  }
}

export class PublicLoginHttpError extends Error {
  constructor(status) {
    super(`HTTP ${status}`);
    this.name = 'PublicLoginHttpError';
    this.status = status;
  }
}

export class PublicLoginTimeoutError extends Error {
  constructor() {
    super('Login request timeout');
    this.name = 'PublicLoginTimeoutError';
  }
}

export class PublicLoginNetworkError extends Error {
  constructor() {
    super('Login request network failure');
    this.name = 'PublicLoginNetworkError';
  }
}

export function isLocalHttpHost(hostname) {
  const host = String(hostname || '').toLowerCase();
  if (host === 'localhost' || host.endsWith('.localhost')) return true;
  if (host === '0.0.0.0' || host === '127.0.0.1' || host === '[::1]' || host === '::1') {
    return true;
  }
  if (/^127\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(host)) return true;
  if (/^10\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(host)) return true;
  if (/^192\.168\.\d{1,3}\.\d{1,3}$/.test(host)) return true;
  const match = /^172\.(\d{1,2})\.\d{1,3}\.\d{1,3}$/.exec(host);
  if (match) {
    const second = Number(match[1]);
    return second >= 16 && second <= 31;
  }
  return false;
}

export function normalizeApiBaseUrl(value) {
  if (typeof value !== 'string') {
    throw new PublicLoginConfigError('Public API base URL must be a string.');
  }

  const raw = value.trim();
  if (!raw) {
    throw new PublicLoginConfigError('Public API base URL is empty.');
  }

  let url;
  try {
    url = new URL(raw);
  } catch (_) {
    throw new PublicLoginConfigError('Public API base URL is invalid.');
  }

  if (url.protocol !== 'https:' && url.protocol !== 'http:') {
    throw new PublicLoginConfigError('Public API base URL must use http or https.');
  }

  if (url.username || url.password) {
    throw new PublicLoginConfigError('Public API base URL must not include credentials.');
  }

  if (url.search || url.hash) {
    throw new PublicLoginConfigError('Public API base URL must not include query or hash.');
  }

  if (url.protocol === 'http:' && !isLocalHttpHost(url.hostname)) {
    throw new PublicLoginConfigError('HTTP is allowed only for local environments.');
  }

  return url.href.replace(/\/+$/, '');
}

export function resolvePublicApiConfig(config) {
  if (!config || typeof config !== 'object') {
    throw new PublicLoginConfigError('Public config is missing.');
  }

  return Object.freeze({
    apiBaseUrl: normalizeApiBaseUrl(config.apiBaseUrl)
  });
}

export function createLoginEndpoint(apiBaseUrl) {
  return `${normalizeApiBaseUrl(apiBaseUrl)}/auth/web/login`;
}

function containsBackslash(value) {
  return String(value || '').indexOf('\\') !== -1;
}

function safelyDecodeRedirect(value) {
  try {
    return decodeURIComponent(value);
  } catch (_) {
    return null;
  }
}

export function sanitizePublicAppRedirect(rawRedirect, origin = 'https://sixapp.local') {
  const raw = String(rawRedirect || '').trim();
  if (!raw) return null;

  const decoded = safelyDecodeRedirect(raw);
  if (decoded === null) return null;
  const candidate = decoded.trim();
  const lowerCandidate = candidate.toLowerCase();

  if (!candidate || containsBackslash(raw) || containsBackslash(candidate)) {
    return null;
  }
  if (!candidate.startsWith('/') || candidate.startsWith('//')) {
    return null;
  }
  if (lowerCandidate.startsWith('javascript:') || lowerCandidate.startsWith('data:')) {
    return null;
  }

  let url;
  try {
    url = new URL(candidate, origin);
  } catch (_) {
    return null;
  }

  if (url.origin !== origin || url.username || url.password) {
    return null;
  }

  if (url.pathname !== '/app' && !url.pathname.startsWith('/app/')) {
    return null;
  }

  return `${url.pathname}${url.search}${url.hash}`;
}

export function resolvePublicLoginRedirect(search, origin = 'https://sixapp.local') {
  const params = new URLSearchParams(String(search || '').replace(/^\?/, ''));
  return sanitizePublicAppRedirect(params.get('redirect'), origin) || '/app';
}

export function loginErrorKeyForStatus(status) {
  if (status === 400) return 'error.invalidData';
  if (status === 401 || status === 403) return 'error.invalidCredentials';
  if (status === 429) return 'error.tooManyAttempts';
  if (status === 500 || status === 502 || status === 503 || status === 504) {
    return 'error.unavailable';
  }
  return 'error.unexpected';
}

export function loginErrorKeyFromError(error) {
  if (error instanceof PublicLoginValidationError) {
    return error.code === 'login'
      ? 'error.requiredLogin'
      : 'error.requiredPassword';
  }
  if (error instanceof PublicLoginConfigError) return 'error.config';
  if (error instanceof PublicLoginHttpError) {
    return loginErrorKeyForStatus(error.status);
  }
  if (error instanceof PublicLoginTimeoutError) return 'error.timeout';
  if (error instanceof PublicLoginNetworkError) return 'error.network';
  return 'error.unexpected';
}

export function buildLoginRequest({
  apiBaseUrl,
  login,
  senha,
}) {
  const normalizedLogin = String(login || '').trim();
  const rawPassword = String(senha || '');
  if (!normalizedLogin) {
    throw new PublicLoginValidationError('login');
  }
  if (!rawPassword) {
    throw new PublicLoginValidationError('senha');
  }

  return Object.freeze({
    endpoint: createLoginEndpoint(apiBaseUrl),
    options: Object.freeze({
      method: 'POST',
      credentials: 'include',
      cache: 'no-store',
      headers: Object.freeze({
        'Content-Type': 'application/json',
        Accept: 'application/json'
      }),
      body: JSON.stringify({
        login: normalizedLogin,
        senha: rawPassword
      })
    })
  });
}

export async function performPublicLogin({
  apiBaseUrl,
  login,
  senha,
  fetchImpl = globalThis.fetch,
  timeoutMs = LOGIN_TIMEOUT_MS,
  AbortControllerClass = globalThis.AbortController,
} = {}) {
  if (typeof fetchImpl !== 'function') {
    throw new PublicLoginNetworkError();
  }

  const request = buildLoginRequest({ apiBaseUrl, login, senha });
  const timeoutDuration =
    Number.isFinite(timeoutMs) && timeoutMs > 0 ? timeoutMs : LOGIN_TIMEOUT_MS;
  const controller =
    typeof AbortControllerClass === 'function'
      ? new AbortControllerClass()
      : null;
  let timeoutId;

  const timeoutPromise = new Promise((_, reject) => {
    timeoutId = setTimeout(() => {
      if (controller) controller.abort();
      reject(new PublicLoginTimeoutError());
    }, timeoutDuration);
  });

  const fetchPromise = fetchImpl(request.endpoint, {
    ...request.options,
    signal: controller ? controller.signal : undefined,
  });

  try {
    const response = await Promise.race([fetchPromise, timeoutPromise]);
    if (response && response.ok) {
      return;
    }
    throw new PublicLoginHttpError(response ? response.status : 0);
  } catch (error) {
    if (
      error instanceof PublicLoginConfigError ||
      error instanceof PublicLoginValidationError ||
      error instanceof PublicLoginHttpError ||
      error instanceof PublicLoginTimeoutError
    ) {
      throw error;
    }
    if (error && error.name === 'AbortError') {
      throw new PublicLoginTimeoutError();
    }
    throw new PublicLoginNetworkError();
  } finally {
    clearTimeout(timeoutId);
  }
}
