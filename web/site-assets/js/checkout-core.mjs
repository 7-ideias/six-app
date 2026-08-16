import {
  normalizeApiBaseUrl,
  resolvePublicApiConfig,
} from './login-core.mjs';
import { normalizePublicLanguage } from './public-locale.mjs';

export const CHECKOUT_TIMEOUT_MS = 12000;
export const CHECKOUT_SUCCESS_PATH = null;
export const CHECKOUT_PAYMENT_METHODS = Object.freeze([
  'card',
  'pix',
  'boleto',
]);

export const CHECKOUT_LANGUAGE_TAGS = Object.freeze({
  pt: 'pt-BR',
  en: 'en-US',
  es: 'es-ES',
});

export const CHECKOUT_DICTIONARY = Object.freeze({
  pt: Object.freeze({
    title: 'SixApp - Checkout',
    description: 'Escolha um plano público do SixApp e mantenha o checkout em modo simulado até a integração de pagamento.',
    ogTitle: 'SixApp - Checkout',
    ogDescription: 'Checkout público em HTML para selecionar um plano do SixApp.',
    twitterTitle: 'SixApp - Checkout',
    twitterDescription: 'Selecione um plano do SixApp sem carregar Flutter.',
    'access.skip': 'Ir para o checkout',
    'brand.aria': 'SixApp',
    'nav.home': 'Voltar',
    'language.aria': 'Selecionar idioma',
    'context.eyebrow': 'Checkout simulado',
    'context.title': 'Escolha como deseja continuar',
    'context.body': 'Os planos são carregados pelo contrato público atual. Nenhum pagamento real será executado nesta página.',
    'plans.legend': 'Plano',
    'plans.help': 'Selecione uma opção disponível.',
    'plans.loading': 'Carregando planos...',
    'plans.featured': 'Destaque',
    'payment.legend': 'Forma de pagamento',
    'payment.help': 'A seleção é mantida apenas para preservar o mock atual.',
    'payment.card': 'Cartão',
    'payment.pix': 'Pix',
    'payment.boleto': 'Boleto',
    'summary.title': 'Resumo',
    'summary.plan': 'Plano',
    'summary.price': 'Valor',
    'summary.cadence': 'Periodicidade',
    'form.submit': 'Continuar',
    'footer.register': 'Criar conta',
    'footer.compatibility': 'Usar versão compatível',
    'noscript.message': 'Para usar esta página, ative o JavaScript. Você também pode acessar a versão compatível.',
    'noscript.link': 'Usar versão compatível',
    'success.simulated': 'Checkout simulado. Nenhuma cobrança foi executada.',
    'error.config': 'Não foi possível preparar o checkout público. Tente novamente mais tarde.',
    'error.noPlans': 'Nenhum plano público foi retornado pelo backend.',
    'error.invalidPlan': 'O plano informado não está disponível. Selecionamos uma opção válida.',
    'error.invalidSelection': 'Selecione um plano disponível para continuar.',
    'error.invalidPayment': 'Selecione uma forma de pagamento válida.',
    'error.invalidData': 'Não foi possível carregar os planos públicos.',
    'error.tooManyAttempts': 'Muitas tentativas em sequência. Aguarde alguns minutos e tente novamente.',
    'error.unavailable': 'Serviço temporariamente indisponível. Tente novamente em instantes.',
    'error.timeout': 'A conexão demorou mais do que o esperado. Tente novamente.',
    'error.network': 'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.',
    'error.unexpected': 'Não foi possível concluir o checkout simulado agora.',
  }),
  en: Object.freeze({
    title: 'SixApp - Checkout',
    description: 'Choose a public SixApp plan and keep checkout simulated until payment integration.',
    ogTitle: 'SixApp - Checkout',
    ogDescription: 'Public HTML checkout to select a SixApp plan.',
    twitterTitle: 'SixApp - Checkout',
    twitterDescription: 'Select a SixApp plan without loading Flutter.',
    'access.skip': 'Skip to checkout',
    'brand.aria': 'SixApp',
    'nav.home': 'Back',
    'language.aria': 'Select language',
    'context.eyebrow': 'Simulated checkout',
    'context.title': 'Choose how to continue',
    'context.body': 'Plans are loaded from the current public contract. No real payment will be executed on this page.',
    'plans.legend': 'Plan',
    'plans.help': 'Select an available option.',
    'plans.loading': 'Loading plans...',
    'plans.featured': 'Featured',
    'payment.legend': 'Payment method',
    'payment.help': 'The selection is kept only to preserve the current mock.',
    'payment.card': 'Card',
    'payment.pix': 'Pix',
    'payment.boleto': 'Boleto',
    'summary.title': 'Summary',
    'summary.plan': 'Plan',
    'summary.price': 'Price',
    'summary.cadence': 'Cadence',
    'form.submit': 'Continue',
    'footer.register': 'Create account',
    'footer.compatibility': 'Use compatible version',
    'noscript.message': 'Enable JavaScript to use this page. You can also access the compatible version.',
    'noscript.link': 'Use compatible version',
    'success.simulated': 'Simulated checkout. No charge was executed.',
    'error.config': 'Could not prepare the public checkout. Try again later.',
    'error.noPlans': 'No public plan was returned by the backend.',
    'error.invalidPlan': 'The requested plan is not available. We selected a valid option.',
    'error.invalidSelection': 'Select an available plan to continue.',
    'error.invalidPayment': 'Select a valid payment method.',
    'error.invalidData': 'Could not load public plans.',
    'error.tooManyAttempts': 'Too many attempts in a row. Wait a few minutes and try again.',
    'error.unavailable': 'Service temporarily unavailable. Try again shortly.',
    'error.timeout': 'The connection took longer than expected. Try again.',
    'error.network': 'Could not connect to the server. Check your connection and try again.',
    'error.unexpected': 'Could not complete the simulated checkout right now.',
  }),
  es: Object.freeze({
    title: 'SixApp - Checkout',
    description: 'Elige un plan público de SixApp y mantén el checkout simulado hasta la integración de pago.',
    ogTitle: 'SixApp - Checkout',
    ogDescription: 'Checkout público en HTML para seleccionar un plan de SixApp.',
    twitterTitle: 'SixApp - Checkout',
    twitterDescription: 'Selecciona un plan de SixApp sin cargar Flutter.',
    'access.skip': 'Ir al checkout',
    'brand.aria': 'SixApp',
    'nav.home': 'Volver',
    'language.aria': 'Seleccionar idioma',
    'context.eyebrow': 'Checkout simulado',
    'context.title': 'Elige cómo continuar',
    'context.body': 'Los planes se cargan desde el contrato público actual. No se ejecutará ningún pago real en esta página.',
    'plans.legend': 'Plan',
    'plans.help': 'Selecciona una opción disponible.',
    'plans.loading': 'Cargando planes...',
    'plans.featured': 'Destacado',
    'payment.legend': 'Método de pago',
    'payment.help': 'La selección se mantiene solo para preservar el mock actual.',
    'payment.card': 'Tarjeta',
    'payment.pix': 'Pix',
    'payment.boleto': 'Boleto',
    'summary.title': 'Resumen',
    'summary.plan': 'Plan',
    'summary.price': 'Valor',
    'summary.cadence': 'Periodicidad',
    'form.submit': 'Continuar',
    'footer.register': 'Crear cuenta',
    'footer.compatibility': 'Usar versión compatible',
    'noscript.message': 'Para usar esta página, activa JavaScript. También puedes acceder a la versión compatible.',
    'noscript.link': 'Usar versión compatible',
    'success.simulated': 'Checkout simulado. No se ejecutó ningún cobro.',
    'error.config': 'No fue posible preparar el checkout público. Intenta más tarde.',
    'error.noPlans': 'El backend no devolvió ningún plan público.',
    'error.invalidPlan': 'El plan informado no está disponible. Seleccionamos una opción válida.',
    'error.invalidSelection': 'Selecciona un plan disponible para continuar.',
    'error.invalidPayment': 'Selecciona un método de pago válido.',
    'error.invalidData': 'No fue posible cargar los planes públicos.',
    'error.tooManyAttempts': 'Demasiados intentos seguidos. Espera unos minutos e inténtalo de nuevo.',
    'error.unavailable': 'Servicio temporalmente indisponible. Intenta nuevamente en instantes.',
    'error.timeout': 'La conexión tardó más de lo esperado. Intenta nuevamente.',
    'error.network': 'No fue posible conectar al servidor. Verifica tu conexión e intenta nuevamente.',
    'error.unexpected': 'No fue posible completar el checkout simulado ahora.',
  }),
});

export class PublicCheckoutConfigError extends Error {
  constructor(message = 'Invalid public checkout configuration') {
    super(message);
    this.name = 'PublicCheckoutConfigError';
  }
}

export class PublicCheckoutHttpError extends Error {
  constructor(status) {
    super(`Public checkout request failed with status ${status}`);
    this.name = 'PublicCheckoutHttpError';
    this.status = status;
  }
}

export class PublicCheckoutTimeoutError extends Error {
  constructor() {
    super('Public checkout request timed out');
    this.name = 'PublicCheckoutTimeoutError';
  }
}

export class PublicCheckoutNetworkError extends Error {
  constructor() {
    super('Public checkout network failure');
    this.name = 'PublicCheckoutNetworkError';
  }
}

export class PublicCheckoutValidationError extends Error {
  constructor(code) {
    super(`Public checkout validation failed: ${code}`);
    this.name = 'PublicCheckoutValidationError';
    this.code = code;
  }
}

export function resolvePublicCheckoutConfig(config) {
  try {
    return resolvePublicApiConfig(config);
  } catch (error) {
    throw new PublicCheckoutConfigError(error.message);
  }
}

export function languageTagForCheckout(language) {
  const normalized = normalizePublicLanguage(language);
  return CHECKOUT_LANGUAGE_TAGS[normalized] || CHECKOUT_LANGUAGE_TAGS.pt;
}

export function currencyForCheckout(language) {
  return normalizePublicLanguage(language) === 'pt' ? 'BRL' : 'USD';
}

export function createCheckoutPlansEndpoint(apiBaseUrl, language) {
  const normalizedBaseUrl = normalizeApiBaseUrl(apiBaseUrl);
  const query = new URLSearchParams({
    locale: languageTagForCheckout(language),
    currency: currencyForCheckout(language),
  });
  return `${normalizedBaseUrl}/public/api/planos?${query.toString()}`;
}

// Alias mantido para não quebrar consumidores antigos durante a publicação.
export function createCheckoutI18nEndpoint(apiBaseUrl, language) {
  return createCheckoutPlansEndpoint(apiBaseUrl, language);
}

export function checkoutErrorKeyForStatus(status) {
  if (status === 429) return 'error.tooManyAttempts';
  if ([400, 401, 403, 404, 409, 422].includes(status)) {
    return 'error.invalidData';
  }
  if (status >= 500 && status <= 599) return 'error.unavailable';
  return 'error.unexpected';
}

export function checkoutErrorKeyFromError(error) {
  if (error instanceof PublicCheckoutConfigError) return 'error.config';
  if (error instanceof PublicCheckoutTimeoutError) return 'error.timeout';
  if (error instanceof PublicCheckoutNetworkError) return 'error.network';
  if (error instanceof PublicCheckoutValidationError) {
    if (error.code === 'payment') return 'error.invalidPayment';
    return 'error.invalidSelection';
  }
  if (error instanceof PublicCheckoutHttpError) {
    return checkoutErrorKeyForStatus(error.status);
  }
  return 'error.unexpected';
}

export function parseCheckoutMessages(responseBody) {
  if (!responseBody || typeof responseBody !== 'object') {
    throw new PublicCheckoutValidationError('catalog');
  }
  if (!Array.isArray(responseBody.planos)) {
    throw new PublicCheckoutValidationError('catalog');
  }
  return responseBody;
}

function cadenceForPeriodicity(periodicity, language) {
  const normalizedLanguage = normalizePublicLanguage(language);
  const labels = {
    pt: {
      GRATUITO: 'para sempre',
      MENSAL: 'por mês',
      ANUAL: 'por ano',
      UNICO: 'pagamento único',
    },
    en: {
      GRATUITO: 'forever',
      MENSAL: 'per month',
      ANUAL: 'per year',
      UNICO: 'one-time payment',
    },
    es: {
      GRATUITO: 'para siempre',
      MENSAL: 'por mes',
      ANUAL: 'por año',
      UNICO: 'pago único',
    },
  };
  return labels[normalizedLanguage]?.[periodicity] || periodicity;
}

function formatPlanPrice(value, currencyCode, language) {
  const amount = Number(value);
  if (!Number.isFinite(amount) || amount < 0) return '';
  try {
    return new Intl.NumberFormat(languageTagForCheckout(language), {
      style: 'currency',
      currency: currencyCode,
      minimumFractionDigits: Number.isInteger(amount) ? 0 : 2,
      maximumFractionDigits: 2,
    }).format(amount);
  } catch (_) {
    return `${currencyCode} ${amount.toFixed(2)}`;
  }
}

function normalizePlanItem(item, language) {
  if (!item || typeof item !== 'object' || Array.isArray(item)) return null;

  const id = typeof item.codigo === 'string' ? item.codigo.trim() : '';
  const name = typeof item.nome === 'string' ? item.nome.trim() : '';
  const pitch = typeof item.descricao === 'string' ? item.descricao.trim() : '';
  const cta = typeof item.chamadaAcao === 'string'
    ? item.chamadaAcao.trim()
    : '';
  const features = Array.isArray(item.beneficios)
    ? item.beneficios.map((value) => String(value).trim()).filter(Boolean)
    : [];
  const featured = item.destaque === true;
  const priceData = item.preco;
  const currencyCode = typeof priceData?.currencyCode === 'string'
    ? priceData.currencyCode.trim().toUpperCase()
    : '';
  const periodicity = typeof priceData?.periodicidade === 'string'
    ? priceData.periodicidade.trim().toUpperCase()
    : '';
  const price = formatPlanPrice(priceData?.valor, currencyCode, language);
  const cadence = cadenceForPeriodicity(periodicity, language);

  if (!id || !name || !price || !cadence || !Array.isArray(item.beneficios) || !cta) {
    return null;
  }

  return Object.freeze({
    id,
    name,
    price,
    cadence,
    pitch,
    features: Object.freeze(features),
    cta,
    featured,
    rawAmount: Number(priceData.valor),
    currencyCode,
    billingPeriod: periodicity,
    conditions: Object.freeze({
      trialDays: Number(item.condicoes?.diasTeste || 0),
      userLimit: item.condicoes?.limiteUsuarios ?? null,
      loyaltyMonths: Number(item.condicoes?.mesesFidelidade || 0),
      cancelAnytime: item.condicoes?.cancelamentoLivre === true,
    }),
  });
}

export function extractCheckoutPlans(catalog, language = 'pt') {
  const plans = catalog && catalog.planos;
  if (!Array.isArray(plans)) return [];
  return plans.map((item) => normalizePlanItem(item, language)).filter(Boolean);
}

export function getCheckoutPlanFromSearch(search) {
  const raw = new URLSearchParams(search || '').get('plan');
  return raw ? raw.trim() : '';
}

export function hasUnsafeCheckoutPriceParam(search) {
  return new URLSearchParams(search || '').has('price');
}

export function resolveSelectedCheckoutPlan(plans, requestedPlan) {
  if (!Array.isArray(plans) || plans.length === 0) {
    return {
      plan: null,
      requestedPlan: requestedPlan || '',
      requestAccepted: false,
      fallbackReason: 'empty',
    };
  }

  const normalizedRequest = String(requestedPlan || '').trim();
  if (normalizedRequest) {
    const matched = plans.find(
      (plan) => plan.id.toLowerCase() === normalizedRequest.toLowerCase(),
    );
    if (matched) {
      return {
        plan: matched,
        requestedPlan: normalizedRequest,
        requestAccepted: true,
        fallbackReason: null,
      };
    }
  }

  const featured = plans.find((plan) => plan.featured) || plans[0];
  return {
    plan: featured,
    requestedPlan: normalizedRequest,
    requestAccepted: !normalizedRequest,
    fallbackReason: normalizedRequest ? 'invalid' : 'default',
  };
}

export function validateCheckoutPaymentMethod(paymentMethod) {
  const normalized = String(paymentMethod || '').trim();
  if (!CHECKOUT_PAYMENT_METHODS.includes(normalized)) {
    throw new PublicCheckoutValidationError('payment');
  }
  return normalized;
}

export function buildCheckoutPayload({
  plan,
  paymentMethod,
  now = () => new Date(),
} = {}) {
  if (!plan || !plan.id || !plan.price || !plan.cadence) {
    throw new PublicCheckoutValidationError('plan');
  }

  return {
    plan: plan.id,
    price: plan.price,
    cadence: plan.cadence,
    paymentMethod: validateCheckoutPaymentMethod(paymentMethod),
    createdAt: now().toISOString(),
  };
}

export async function fetchPublicCheckoutMessages({
  apiBaseUrl,
  language,
  fetchImpl = globalThis.fetch,
  timeoutMs = CHECKOUT_TIMEOUT_MS,
} = {}) {
  if (typeof fetchImpl !== 'function') {
    throw new PublicCheckoutConfigError('Fetch API unavailable');
  }

  const endpoint = createCheckoutPlansEndpoint(apiBaseUrl, language);
  const controller = new AbortController();
  let timeoutId;
  const timeoutPromise = new Promise((_, reject) => {
    timeoutId = setTimeout(() => {
      controller.abort();
      reject(new PublicCheckoutTimeoutError());
    }, timeoutMs);
  });

  try {
    const response = await Promise.race([
      fetchImpl(endpoint, {
        method: 'GET',
        cache: 'no-store',
        signal: controller.signal,
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
        },
      }),
      timeoutPromise,
    ]);

    if (!response || !response.ok) {
      throw new PublicCheckoutHttpError(response?.status || 0);
    }

    return parseCheckoutMessages(await response.json());
  } catch (error) {
    if (error instanceof PublicCheckoutHttpError ||
        error instanceof PublicCheckoutTimeoutError ||
        error instanceof PublicCheckoutValidationError) {
      throw error;
    }
    if (error && error.name === 'AbortError') {
      throw new PublicCheckoutTimeoutError();
    }
    throw new PublicCheckoutNetworkError();
  } finally {
    clearTimeout(timeoutId);
  }
}

export async function loadPublicCheckoutPlans({
  config,
  language,
  fetchImpl = globalThis.fetch,
  timeoutMs = CHECKOUT_TIMEOUT_MS,
} = {}) {
  const { apiBaseUrl } = resolvePublicCheckoutConfig(config);
  const catalog = await fetchPublicCheckoutMessages({
    apiBaseUrl,
    language,
    fetchImpl,
    timeoutMs,
  });
  const plans = extractCheckoutPlans(catalog, language);
  if (plans.length === 0) {
    throw new PublicCheckoutValidationError('plans');
  }
  return plans;
}
