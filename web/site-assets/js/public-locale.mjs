export const PUBLIC_LOCALE_STORAGE_KEY = 'sixapp.public.locale';

export const SUPPORTED_PUBLIC_LANGUAGES = Object.freeze(['pt', 'en', 'es']);

export function normalizePublicLanguage(value) {
  const code = String(value || '').trim().toLowerCase();
  if (code.startsWith('en')) return 'en';
  if (code.startsWith('es')) return 'es';
  return 'pt';
}

export function documentLanguageForPublicLanguage(language) {
  const normalized = normalizePublicLanguage(language);
  return normalized === 'pt' ? 'pt-BR' : normalized;
}

export function getStoredPublicLanguage(storage = globalThis.localStorage) {
  try {
    return storage.getItem(PUBLIC_LOCALE_STORAGE_KEY);
  } catch (_) {
    return null;
  }
}

export function storePublicLanguage(
  language,
  storage = globalThis.localStorage,
) {
  try {
    storage.setItem(PUBLIC_LOCALE_STORAGE_KEY, normalizePublicLanguage(language));
  } catch (_) {}
}

export function getBrowserPublicLanguage(navigatorRef = globalThis.navigator) {
  const languages = navigatorRef && navigatorRef.languages;
  const preferred =
    languages && languages.length > 0
      ? languages[0]
      : navigatorRef && navigatorRef.language;
  return normalizePublicLanguage(preferred || 'pt-BR');
}

export function selectPublicLanguage({
  storage = globalThis.localStorage,
  navigatorRef = globalThis.navigator,
} = {}) {
  const stored = getStoredPublicLanguage(storage);
  if (stored) return normalizePublicLanguage(stored);
  return getBrowserPublicLanguage(navigatorRef);
}

export function assertPublicDictionaryParity(dictionary) {
  const languages = SUPPORTED_PUBLIC_LANGUAGES;
  const reference = Object.keys(dictionary.pt || {}).sort();
  for (const language of languages) {
    const keys = Object.keys(dictionary[language] || {}).sort();
    if (keys.length !== reference.length) {
      throw new Error(`Dictionary ${language} has ${keys.length} keys; expected ${reference.length}.`);
    }
    for (let index = 0; index < reference.length; index += 1) {
      if (keys[index] !== reference[index]) {
        throw new Error(`Dictionary ${language} is missing key ${reference[index]}.`);
      }
    }
  }
  return true;
}

function setMeta(documentRef, name, content) {
  const node = documentRef.querySelector(`meta[name="${name}"]`);
  if (node) node.setAttribute('content', content);
}

function setProperty(documentRef, property, content) {
  const node = documentRef.querySelector(`meta[property="${property}"]`);
  if (node) node.setAttribute('content', content);
}

export function applyPublicLanguage({
  documentRef = globalThis.document,
  dictionary,
  language,
  storage = globalThis.localStorage,
  persist = true,
} = {}) {
  assertPublicDictionaryParity(dictionary);
  const normalized = normalizePublicLanguage(language);
  const copy = dictionary[normalized] || dictionary.pt;

  documentRef.documentElement.lang =
    documentLanguageForPublicLanguage(normalized);
  documentRef.title = copy.title;
  setMeta(documentRef, 'description', copy.description);
  setProperty(documentRef, 'og:title', copy.ogTitle || copy.title);
  setProperty(
    documentRef,
    'og:description',
    copy.ogDescription || copy.description,
  );
  setMeta(documentRef, 'twitter:title', copy.twitterTitle || copy.title);
  setMeta(
    documentRef,
    'twitter:description',
    copy.twitterDescription || copy.description,
  );

  documentRef.querySelectorAll('[data-i18n]').forEach((node) => {
    const key = node.getAttribute('data-i18n');
    if (copy[key]) node.textContent = copy[key];
  });

  documentRef.querySelectorAll('[data-i18n-aria]').forEach((node) => {
    const key = node.getAttribute('data-i18n-aria');
    if (copy[key]) node.setAttribute('aria-label', copy[key]);
  });

  documentRef.querySelectorAll('[data-i18n-alt]').forEach((node) => {
    const key = node.getAttribute('data-i18n-alt');
    if (copy[key]) node.setAttribute('alt', copy[key]);
  });

  documentRef.querySelectorAll('[data-i18n-placeholder]').forEach((node) => {
    const key = node.getAttribute('data-i18n-placeholder');
    if (copy[key]) node.setAttribute('placeholder', copy[key]);
  });

  documentRef.querySelectorAll('[data-lang-option]').forEach((button) => {
    button.setAttribute(
      'aria-pressed',
      button.getAttribute('data-lang-option') === normalized ? 'true' : 'false',
    );
  });

  if (persist) {
    storePublicLanguage(normalized, storage);
  }

  return normalized;
}

export function setupPublicLanguageSwitcher({
  documentRef = globalThis.document,
  dictionary,
  onChange,
  storage = globalThis.localStorage,
} = {}) {
  documentRef.querySelectorAll('[data-lang-option]').forEach((button) => {
    button.addEventListener('click', () => {
      const language = button.getAttribute('data-lang-option');
      const normalized = applyPublicLanguage({
        documentRef,
        dictionary,
        language,
        storage,
      });
      if (typeof onChange === 'function') {
        onChange(normalized);
      }
    });
  });
}

export function isSixAppFlutterServiceWorker(
  registration,
  locationRef = globalThis.location,
) {
  const worker =
    registration && (registration.active || registration.waiting || registration.installing);
  if (!worker || !worker.scriptURL || !registration.scope) return false;
  try {
    const scriptUrl = new URL(worker.scriptURL);
    const scopeUrl = new URL(registration.scope);
    return scriptUrl.origin === locationRef.origin &&
      scopeUrl.origin === locationRef.origin &&
      scriptUrl.pathname === '/flutter_service_worker.js' &&
      scopeUrl.pathname === '/';
  } catch (_) {
    return false;
  }
}

export function isSixAppFlutterCacheName(cacheName) {
  return cacheName === 'flutter-app-cache' ||
    cacheName === 'flutter-temp-cache' ||
    cacheName === 'flutter-app-manifest' ||
    cacheName.startsWith('flutter-app-cache-') ||
    cacheName.startsWith('flutter-temp-cache-') ||
    cacheName.startsWith('flutter-app-manifest-');
}

export function clearSixAppFlutterCaches(cachesRef = globalThis.caches) {
  if (!cachesRef || typeof cachesRef.keys !== 'function') {
    return Promise.resolve();
  }
  return cachesRef.keys().then((cacheNames) => Promise.all(
    cacheNames
      .filter(isSixAppFlutterCacheName)
      .map((cacheName) => cachesRef.delete(cacheName)),
  ));
}

export function cleanupLegacyFlutterWorker({
  navigatorRef = globalThis.navigator,
  cachesRef = globalThis.caches,
  locationRef = globalThis.location,
} = {}) {
  if (!navigatorRef || !navigatorRef.serviceWorker) {
    return Promise.resolve();
  }
  return navigatorRef.serviceWorker.getRegistrations()
    .then((registrations) => Promise.all(
      registrations
        .filter((registration) => isSixAppFlutterServiceWorker(
          registration,
          locationRef,
        ))
        .map((registration) => registration.unregister()),
    ))
    .then(() => clearSixAppFlutterCaches(cachesRef))
    .catch(() => {});
}
