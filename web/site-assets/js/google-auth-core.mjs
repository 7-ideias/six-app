const GOOGLE_GSI_SRC = 'https://accounts.google.com/gsi/client';
export const GOOGLE_AUTH_TIMEOUT_MS = 20000;

export class PublicGoogleAuthError extends Error {
  constructor(message, { status = null, code = null } = {}) {
    super(message);
    this.name = 'PublicGoogleAuthError';
    this.status = status;
    this.code = code;
  }
}

export function resolveGoogleWebClientId(config) {
  const value = String(config?.googleWebClientId || '').trim();
  if (!/^[0-9]+-[a-z0-9_-]+\.apps\.googleusercontent\.com$/i.test(value)) {
    throw new PublicGoogleAuthError('Google Web Client ID ausente ou invalido.', {
      code: 'config',
    });
  }
  return value;
}

export function googleBackendLanguage(language) {
  const normalized = String(language || '').trim().toLowerCase();
  if (normalized.startsWith('en')) return 'en-US';
  if (normalized.startsWith('es')) return 'es-ES';
  return 'pt-BR';
}

function normalizeApiBaseUrl(apiBaseUrl) {
  const raw = String(apiBaseUrl || '').trim().replace(/\/+$/, '');
  let url;
  try {
    url = new URL(raw);
  } catch (_) {
    throw new PublicGoogleAuthError('API base URL invalida.', { code: 'config' });
  }
  if (url.protocol !== 'https:' && url.hostname !== 'localhost' && url.hostname !== '127.0.0.1') {
    throw new PublicGoogleAuthError('API publica deve usar HTTPS.', { code: 'config' });
  }
  return url.href.replace(/\/+$/, '');
}

function extractBackendCode(body) {
  const text = String(body || '').trim();
  if (!text) return null;
  try {
    const parsed = JSON.parse(text);
    const candidates = [parsed?.message, parsed?.detail, parsed?.error, parsed?.code];
    for (const candidate of candidates) {
      if (typeof candidate === 'string' && candidate.trim()) return candidate.trim();
    }
  } catch (_) {}
  const match = text.match(/GOOGLE_[A-Z0-9_]+/);
  return match ? match[0] : null;
}

async function performGoogleRequest({
  apiBaseUrl,
  idToken,
  fluxo,
  aceiteTermos,
  idioma,
  senha,
  link = false,
  fetchImpl = globalThis.fetch,
  timeoutMs = GOOGLE_AUTH_TIMEOUT_MS,
  AbortControllerClass = globalThis.AbortController,
} = {}) {
  if (typeof fetchImpl !== 'function') {
    throw new PublicGoogleAuthError('Fetch indisponivel.', { code: 'network' });
  }
  const credential = String(idToken || '').trim();
  if (!credential) {
    throw new PublicGoogleAuthError('Google nao retornou uma credencial valida.', {
      code: 'missingCredential',
    });
  }

  const body = {
    idToken: credential,
    fluxo: String(fluxo || 'LOGIN').toUpperCase(),
    aceiteTermos: Boolean(aceiteTermos),
    idioma: googleBackendLanguage(idioma),
  };
  if (link) {
    const password = String(senha || '');
    if (!password) {
      throw new PublicGoogleAuthError('Senha atual obrigatoria.', { code: 'passwordRequired' });
    }
    body.senha = password;
  }

  const controller = typeof AbortControllerClass === 'function'
    ? new AbortControllerClass()
    : null;
  const timeoutDuration = Number.isFinite(timeoutMs) && timeoutMs > 0
    ? timeoutMs
    : GOOGLE_AUTH_TIMEOUT_MS;
  let timeoutId;

  const timeoutPromise = new Promise((_, reject) => {
    timeoutId = setTimeout(() => {
      if (controller) controller.abort();
      reject(new PublicGoogleAuthError('Tempo limite excedido.', { code: 'timeout' }));
    }, timeoutDuration);
  });

  const endpoint = `${normalizeApiBaseUrl(apiBaseUrl)}/auth/web/google${link ? '/link' : ''}`;
  const fetchPromise = fetchImpl(endpoint, {
    method: 'POST',
    credentials: 'include',
    cache: 'no-store',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify(body),
    signal: controller ? controller.signal : undefined,
  });

  try {
    const response = await Promise.race([fetchPromise, timeoutPromise]);
    if (response?.ok) {
      return response;
    }
    const responseBody = response ? await response.text() : '';
    throw new PublicGoogleAuthError('Google authentication backend rejected request.', {
      status: response?.status ?? 0,
      code: extractBackendCode(responseBody),
    });
  } catch (error) {
    if (error instanceof PublicGoogleAuthError) throw error;
    if (error?.name === 'AbortError') {
      throw new PublicGoogleAuthError('Tempo limite excedido.', { code: 'timeout' });
    }
    throw new PublicGoogleAuthError('Falha de rede na autenticacao Google.', {
      code: 'network',
    });
  } finally {
    clearTimeout(timeoutId);
  }
}

export function performGoogleLogin(options = {}) {
  return performGoogleRequest({ ...options, fluxo: 'LOGIN', link: false });
}

export function performGoogleRegistration(options = {}) {
  return performGoogleRequest({ ...options, fluxo: 'CADASTRO', link: false });
}

export function performGoogleLink(options = {}) {
  return performGoogleRequest({ ...options, link: true });
}

export function googleErrorKey(error, mode = 'login') {
  if (!(error instanceof PublicGoogleAuthError)) return 'google.error.unexpected';
  if (error.code === 'config') return 'google.error.config';
  if (error.code === 'timeout') return 'google.error.timeout';
  if (error.code === 'network') return 'google.error.network';
  if (error.code === 'passwordRequired') return 'google.link.passwordRequired';
  if (error.status === 409 || error.code === 'GOOGLE_VINCULACAO_NECESSARIA') {
    return 'google.link.required';
  }
  if (error.status === 404 || error.code === 'GOOGLE_CONTA_NAO_CADASTRADA') {
    return mode === 'login' ? 'google.error.registrationRequired' : 'google.error.notFound';
  }
  if (error.status === 422 || error.code === 'GOOGLE_ACEITE_TERMOS_OBRIGATORIO') {
    return 'google.error.termsRequired';
  }
  if (error.status === 401 || error.status === 403) {
    return 'google.error.invalidCredential';
  }
  if (error.status >= 500) return 'google.error.unavailable';
  return 'google.error.unexpected';
}

let gsiPromise;

export function loadGoogleIdentityServices({
  documentRef = globalThis.document,
  windowRef = globalThis.window,
  timeoutMs = 12000,
} = {}) {
  if (windowRef?.google?.accounts?.id) {
    return Promise.resolve(windowRef.google.accounts.id);
  }
  if (gsiPromise) return gsiPromise;

  gsiPromise = new Promise((resolve, reject) => {
    const existing = documentRef.querySelector(`script[src="${GOOGLE_GSI_SRC}"]`);
    const script = existing || documentRef.createElement('script');
    let settled = false;
    const finish = () => {
      if (settled) return;
      settled = true;
      clearTimeout(timeoutId);
      if (windowRef?.google?.accounts?.id) {
        resolve(windowRef.google.accounts.id);
      } else {
        reject(new PublicGoogleAuthError('Google Identity Services indisponivel.', {
          code: 'gsiUnavailable',
        }));
      }
    };
    const fail = () => {
      if (settled) return;
      settled = true;
      clearTimeout(timeoutId);
      reject(new PublicGoogleAuthError('Falha ao carregar Google Identity Services.', {
        code: 'gsiUnavailable',
      }));
    };
    const timeoutId = setTimeout(fail, timeoutMs);

    script.addEventListener('load', finish, { once: true });
    script.addEventListener('error', fail, { once: true });
    if (!existing) {
      script.src = GOOGLE_GSI_SRC;
      script.async = true;
      script.defer = true;
      script.referrerPolicy = 'no-referrer-when-downgrade';
      documentRef.head.appendChild(script);
    }
  });

  return gsiPromise;
}

export async function renderGoogleButton({
  container,
  clientId,
  callback,
  language = 'pt',
  text = 'continue_with',
  documentRef = globalThis.document,
  windowRef = globalThis.window,
} = {}) {
  if (!container) {
    throw new PublicGoogleAuthError('Container Google ausente.', { code: 'config' });
  }
  await loadGoogleIdentityServices({ documentRef, windowRef });
  const googleId = windowRef.google.accounts.id;
  googleId.initialize({
    client_id: clientId,
    callback,
    auto_select: false,
    cancel_on_tap_outside: true,
    itp_support: true,
    use_fedcm_for_prompt: true,
  });
  container.replaceChildren();
  googleId.renderButton(container, {
    type: 'standard',
    theme: 'outline',
    size: 'large',
    text,
    shape: 'pill',
    logo_alignment: 'left',
    width: Math.max(240, Math.floor(container.clientWidth || 360)),
    locale: String(language || 'pt').toLowerCase(),
  });
}
