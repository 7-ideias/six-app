import { normalizeApiBaseUrl } from './login-core.mjs';
import { normalizePublicLanguage } from './public-locale.mjs';

const LANGUAGE_TAGS = Object.freeze({
  pt: 'pt-BR',
  en: 'en-US',
  es: 'es-ES',
});

export const CATALOG_DICTIONARY = Object.freeze({
  pt: Object.freeze({
    title: 'Catálogo virtual',
    description: 'Consulte produtos disponíveis e envie sua seleção para o comércio.',
    ogTitle: 'Catálogo virtual',
    ogDescription: 'Produtos selecionados pelo comércio, disponíveis em um catálogo leve e seguro.',
    twitterTitle: 'Catálogo virtual',
    twitterDescription: 'Consulte produtos e envie sua seleção ao comércio.',
    'access.skip': 'Ir para os produtos',
    'language.aria': 'Selecionar idioma',
    'catalog.eyebrow': 'Catálogo virtual',
    'catalog.search': 'Buscar produtos',
    'catalog.searchPlaceholder': 'Busque por nome ou modelo...',
    'catalog.loading': 'Carregando catálogo...',
    'catalog.empty': 'Este comércio ainda não publicou produtos.',
    'catalog.noResults': 'Nenhum produto corresponde à sua busca.',
    'catalog.products': 'Produtos disponíveis',
    'catalog.itemsCount': '{count} itens',
    'company.contact': 'Contato',
    'company.hours': 'Horários',
    'company.closed': 'Fechado',
    'product.choose': 'Escolher',
    'product.chosen': 'Escolhido',
    'product.model': 'Modelo',
    'selection.title': 'Sua seleção',
    'selection.empty': 'Marque os produtos que deseja reservar.',
    'selection.quantity': 'Quantidade',
    'selection.remove': 'Remover',
    'selection.total': 'Total estimado',
    'selection.notice': 'A disponibilidade será confirmada pelo comércio.',
    'form.title': 'Seus dados',
    'form.name': 'Nome',
    'form.namePlaceholder': 'Como podemos chamar você?',
    'form.phone': 'Telefone ou WhatsApp',
    'form.phonePlaceholder': 'Informe seu telefone',
    'form.email': 'E-mail (opcional)',
    'form.emailPlaceholder': 'voce@exemplo.com',
    'form.notes': 'Observação (opcional)',
    'form.notesPlaceholder': 'Cor, tamanho ou outra preferência',
    'form.submit': 'Enviar reserva',
    'form.sending': 'Enviando...',
    'success.title': 'Seleção enviada',
    'success.body': 'O comércio recebeu sua reserva sob o protocolo {protocol}.',
    'poweredBy': 'Catálogo protegido por SixoApp',
    'error.config': 'Não foi possível preparar o catálogo.',
    'error.token': 'Este link de catálogo é inválido.',
    'error.notFound': 'Este catálogo não está disponível.',
    'error.invalidData': 'O catálogo retornou dados inválidos.',
    'error.tooManyAttempts': 'Muitas tentativas. Aguarde alguns minutos.',
    'error.unavailable': 'Serviço temporariamente indisponível.',
    'error.timeout': 'A conexão demorou mais do que o esperado.',
    'error.network': 'Não foi possível conectar ao servidor.',
    'error.unexpected': 'Não foi possível concluir esta operação.',
    'error.name': 'Informe seu nome.',
    'error.contact': 'Informe um telefone ou e-mail.',
    'error.email': 'Informe um e-mail válido.',
    'error.items': 'Escolha pelo menos um produto.',
  }),
  en: Object.freeze({
    title: 'Online catalog',
    description: 'Browse available products and send your selection to the business.',
    ogTitle: 'Online catalog',
    ogDescription: 'Products selected by the business in a lightweight and secure catalog.',
    twitterTitle: 'Online catalog',
    twitterDescription: 'Browse products and send your selection to the business.',
    'access.skip': 'Skip to products',
    'language.aria': 'Select language',
    'catalog.eyebrow': 'Online catalog',
    'catalog.search': 'Search products',
    'catalog.searchPlaceholder': 'Search by name or model...',
    'catalog.loading': 'Loading catalog...',
    'catalog.empty': 'This business has not published products yet.',
    'catalog.noResults': 'No products match your search.',
    'catalog.products': 'Available products',
    'catalog.itemsCount': '{count} items',
    'company.contact': 'Contact',
    'company.hours': 'Hours',
    'company.closed': 'Closed',
    'product.choose': 'Choose',
    'product.chosen': 'Chosen',
    'product.model': 'Model',
    'selection.title': 'Your selection',
    'selection.empty': 'Choose the products you would like to reserve.',
    'selection.quantity': 'Quantity',
    'selection.remove': 'Remove',
    'selection.total': 'Estimated total',
    'selection.notice': 'Availability will be confirmed by the business.',
    'form.title': 'Your details',
    'form.name': 'Name',
    'form.namePlaceholder': 'What should we call you?',
    'form.phone': 'Phone or WhatsApp',
    'form.phonePlaceholder': 'Enter your phone number',
    'form.email': 'Email (optional)',
    'form.emailPlaceholder': 'you@example.com',
    'form.notes': 'Notes (optional)',
    'form.notesPlaceholder': 'Color, size, or another preference',
    'form.submit': 'Send reservation',
    'form.sending': 'Sending...',
    'success.title': 'Selection sent',
    'success.body': 'The business received your reservation under reference {protocol}.',
    'poweredBy': 'Catalog protected by SixoApp',
    'error.config': 'Could not prepare the catalog.',
    'error.token': 'This catalog link is invalid.',
    'error.notFound': 'This catalog is not available.',
    'error.invalidData': 'The catalog returned invalid data.',
    'error.tooManyAttempts': 'Too many attempts. Wait a few minutes.',
    'error.unavailable': 'Service temporarily unavailable.',
    'error.timeout': 'The connection took longer than expected.',
    'error.network': 'Could not connect to the server.',
    'error.unexpected': 'Could not complete this operation.',
    'error.name': 'Enter your name.',
    'error.contact': 'Enter a phone number or email.',
    'error.email': 'Enter a valid email address.',
    'error.items': 'Choose at least one product.',
  }),
  es: Object.freeze({
    title: 'Catálogo virtual',
    description: 'Consulta productos disponibles y envía tu selección al comercio.',
    ogTitle: 'Catálogo virtual',
    ogDescription: 'Productos seleccionados por el comercio en un catálogo ligero y seguro.',
    twitterTitle: 'Catálogo virtual',
    twitterDescription: 'Consulta productos y envía tu selección al comercio.',
    'access.skip': 'Ir a los productos',
    'language.aria': 'Seleccionar idioma',
    'catalog.eyebrow': 'Catálogo virtual',
    'catalog.search': 'Buscar productos',
    'catalog.searchPlaceholder': 'Busca por nombre o modelo...',
    'catalog.loading': 'Cargando catálogo...',
    'catalog.empty': 'Este comercio aún no publicó productos.',
    'catalog.noResults': 'Ningún producto coincide con tu búsqueda.',
    'catalog.products': 'Productos disponibles',
    'catalog.itemsCount': '{count} ítems',
    'company.contact': 'Contacto',
    'company.hours': 'Horarios',
    'company.closed': 'Cerrado',
    'product.choose': 'Elegir',
    'product.chosen': 'Elegido',
    'product.model': 'Modelo',
    'selection.title': 'Tu selección',
    'selection.empty': 'Marca los productos que deseas reservar.',
    'selection.quantity': 'Cantidad',
    'selection.remove': 'Eliminar',
    'selection.total': 'Total estimado',
    'selection.notice': 'La disponibilidad será confirmada por el comercio.',
    'form.title': 'Tus datos',
    'form.name': 'Nombre',
    'form.namePlaceholder': '¿Cómo podemos llamarte?',
    'form.phone': 'Teléfono o WhatsApp',
    'form.phonePlaceholder': 'Informa tu teléfono',
    'form.email': 'Correo (opcional)',
    'form.emailPlaceholder': 'tu@ejemplo.com',
    'form.notes': 'Observación (opcional)',
    'form.notesPlaceholder': 'Color, tamaño u otra preferencia',
    'form.submit': 'Enviar reserva',
    'form.sending': 'Enviando...',
    'success.title': 'Selección enviada',
    'success.body': 'El comercio recibió tu reserva con el protocolo {protocol}.',
    'poweredBy': 'Catálogo protegido por SixoApp',
    'error.config': 'No fue posible preparar el catálogo.',
    'error.token': 'Este enlace de catálogo no es válido.',
    'error.notFound': 'Este catálogo no está disponible.',
    'error.invalidData': 'El catálogo devolvió datos no válidos.',
    'error.tooManyAttempts': 'Demasiados intentos. Espera unos minutos.',
    'error.unavailable': 'Servicio temporalmente no disponible.',
    'error.timeout': 'La conexión tardó más de lo esperado.',
    'error.network': 'No fue posible conectar al servidor.',
    'error.unexpected': 'No fue posible completar esta operación.',
    'error.name': 'Informa tu nombre.',
    'error.contact': 'Informa un teléfono o correo.',
    'error.email': 'Informa un correo válido.',
    'error.items': 'Elige al menos un producto.',
  }),
});

export class CatalogConfigError extends Error {}
export class CatalogTokenError extends Error {}
export class CatalogDataError extends Error {}
export class CatalogTimeoutError extends Error {}
export class CatalogNetworkError extends Error {}
export class CatalogValidationError extends Error {
  constructor(code) {
    super(`Catalog validation failed: ${code}`);
    this.code = code;
  }
}
export class CatalogHttpError extends Error {
  constructor(status) {
    super(`Catalog request failed with status ${status}`);
    this.status = status;
  }
}

export function catalogLanguageTag(language) {
  return LANGUAGE_TAGS[normalizePublicLanguage(language)] || LANGUAGE_TAGS.pt;
}

export function getCatalogTokenFromSearch(search) {
  const token = new URLSearchParams(String(search || '')).get('token')?.trim() || '';
  if (!/^[A-Za-z0-9_-]{16,128}$/.test(token)) {
    throw new CatalogTokenError('Invalid catalog token');
  }
  return token;
}

function resolveApiBaseUrl(config) {
  try {
    return normalizeApiBaseUrl(config?.apiBaseUrl);
  } catch (_) {
    throw new CatalogConfigError('Invalid public catalog configuration');
  }
}

export function createCatalogEndpoint(apiBaseUrl, token) {
  return `${normalizeApiBaseUrl(apiBaseUrl)}/public/api/catalogos/${encodeURIComponent(token)}`;
}

export function createReservationEndpoint(apiBaseUrl, token) {
  return `${createCatalogEndpoint(apiBaseUrl, token)}/reservas`;
}

function normalizeProduct(item) {
  const price = Number(item?.precoVenda ?? 0);
  if (!item || !item.id || !item.nomeProduto || !Number.isFinite(price) || price < 0) {
    throw new CatalogDataError('Invalid catalog product');
  }
  return Object.freeze({
    id: String(item.id),
    name: String(item.nomeProduto).trim(),
    model: String(item.modeloProduto || '').trim(),
    type: String(item.tipoProduto || 'PRODUTO').trim(),
    price,
    imageUrl: String(item.imagemUrl || '').trim(),
    imageBase64: String(item.imagemBase64 || '').trim(),
  });
}

function normalizeCatalogPersonalization(value) {
  const source = value && typeof value === 'object' ? value : {};
  const accent = String(source.corPrincipal || '').trim().toUpperCase();
  const style = String(source.estilo || '').trim().toUpperCase();
  const density = String(source.densidade || '').trim().toUpperCase();
  return Object.freeze({
    title: String(source.titulo || '').trim().slice(0, 80),
    description: String(source.descricao || '').trim().slice(0, 240),
    accentColor: /^#[0-9A-F]{6}$/.test(accent) ? accent : '#126BFF',
    style: ['CLASSICO', 'MINIMALISTA', 'EXPRESSIVO'].includes(style)
      ? style
      : 'CLASSICO',
    density: ['CONFORTAVEL', 'COMPACTA'].includes(density)
      ? density
      : 'CONFORTAVEL',
    showPrices: source.exibirPrecos !== false,
    showContact: source.exibirContato !== false,
    showAddress: source.exibirEndereco !== false,
  });
}

export function normalizeCatalogResponse(body) {
  if (!body || typeof body !== 'object' || !body.empresa || !Array.isArray(body.produtos)) {
    throw new CatalogDataError('Invalid catalog response');
  }
  return Object.freeze({
    locale: String(body.locale || 'pt-BR'),
    currencyCode: String(body.currencyCode || 'BRL').toUpperCase(),
    generatedAt: String(body.geradoEm || ''),
    personalization: normalizeCatalogPersonalization(body.personalizacao),
    company: Object.freeze({
      legalName: String(body.empresa.nomeEmpresa || '').trim(),
      name: String(body.empresa.nomeFantasia || body.empresa.nomeEmpresa || '').trim(),
      phone: String(body.empresa.telefone || '').trim(),
      whatsapp: String(body.empresa.whatsapp || '').trim(),
      email: String(body.empresa.email || '').trim(),
      site: String(body.empresa.site || '').trim(),
      address: String(body.empresa.endereco || '').trim(),
      logoBase64: String(body.empresa.logoBase64 || '').trim(),
      hours: Array.isArray(body.empresa.horariosAtendimento)
        ? body.empresa.horariosAtendimento.map((hour) => Object.freeze({
          day: String(hour?.diaSemana || ''),
          closed: hour?.fechado === true,
          start: String(hour?.inicio || ''),
          end: String(hour?.fim || ''),
        }))
        : [],
    }),
    products: Object.freeze(body.produtos.map(normalizeProduct)),
  });
}

export function formatCatalogMoney(value, currencyCode, locale) {
  try {
    return new Intl.NumberFormat(locale || 'pt-BR', {
      style: 'currency',
      currency: currencyCode || 'BRL',
    }).format(Number(value) || 0);
  } catch (_) {
    return `${currencyCode || ''} ${(Number(value) || 0).toFixed(2)}`.trim();
  }
}

export function setCatalogSelectionQuantity(selection, productId, quantity) {
  const next = { ...(selection || {}) };
  const normalized = Math.trunc(Number(quantity));
  if (!Number.isFinite(normalized) || normalized <= 0) {
    delete next[productId];
  } else {
    next[productId] = Math.min(normalized, 99);
  }
  return next;
}

export function calculateCatalogSelection(catalog, selection) {
  const productsById = new Map((catalog?.products || []).map((product) => [product.id, product]));
  const items = Object.entries(selection || {})
    .map(([productId, quantity]) => ({
      product: productsById.get(productId),
      quantity: Math.trunc(Number(quantity)),
    }))
    .filter((item) => item.product && item.quantity > 0);
  return {
    items,
    quantity: items.reduce((total, item) => total + item.quantity, 0),
    total: items.reduce((total, item) => total + (item.product.price * item.quantity), 0),
  };
}

export function buildCatalogReservationPayload({
  idempotencyKey,
  name,
  phone,
  email,
  notes,
  selection,
}) {
  const normalizedName = String(name || '').trim();
  const normalizedPhone = String(phone || '').trim();
  const normalizedEmail = String(email || '').trim();
  const items = Object.entries(selection || {})
    .map(([idProduto, quantity]) => ({
      idProduto,
      quantidade: Math.trunc(Number(quantity)),
    }))
    .filter((item) => item.idProduto && item.quantidade > 0);

  if (!normalizedName) throw new CatalogValidationError('name');
  if (!normalizedPhone && !normalizedEmail) throw new CatalogValidationError('contact');
  if (normalizedEmail && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
    throw new CatalogValidationError('email');
  }
  if (!items.length) throw new CatalogValidationError('items');
  if (!/^[A-Za-z0-9_-]{8,100}$/.test(String(idempotencyKey || ''))) {
    throw new CatalogValidationError('idempotency');
  }

  return {
    idempotencyKey,
    cliente: {
      nome: normalizedName,
      telefone: normalizedPhone || null,
      email: normalizedEmail || null,
    },
    itens: items,
    observacao: String(notes || '').trim() || null,
  };
}

async function executeJsonRequest({ url, options, fetchImpl, timeoutMs }) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetchImpl(url, { ...options, signal: controller.signal });
    if (!response.ok) throw new CatalogHttpError(response.status);
    return await response.json();
  } catch (error) {
    if (error instanceof CatalogHttpError) throw error;
    if (controller.signal.aborted) throw new CatalogTimeoutError('Catalog request timed out');
    throw new CatalogNetworkError('Catalog network failure');
  } finally {
    clearTimeout(timeout);
  }
}

export async function fetchPublicCatalog({
  config,
  token,
  fetchImpl = globalThis.fetch,
  timeoutMs = 12000,
}) {
  const apiBaseUrl = resolveApiBaseUrl(config);
  const body = await executeJsonRequest({
    url: createCatalogEndpoint(apiBaseUrl, token),
    fetchImpl,
    timeoutMs,
    options: {
      method: 'GET',
      cache: 'no-store',
      headers: { Accept: 'application/json' },
    },
  });
  return normalizeCatalogResponse(body);
}

export async function submitCatalogReservation({
  config,
  token,
  payload,
  fetchImpl = globalThis.fetch,
  timeoutMs = 12000,
}) {
  const apiBaseUrl = resolveApiBaseUrl(config);
  return executeJsonRequest({
    url: createReservationEndpoint(apiBaseUrl, token),
    fetchImpl,
    timeoutMs,
    options: {
      method: 'POST',
      cache: 'no-store',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    },
  });
}

export function catalogErrorKey(error) {
  if (error instanceof CatalogConfigError) return 'error.config';
  if (error instanceof CatalogTokenError) return 'error.token';
  if (error instanceof CatalogDataError) return 'error.invalidData';
  if (error instanceof CatalogTimeoutError) return 'error.timeout';
  if (error instanceof CatalogNetworkError) return 'error.network';
  if (error instanceof CatalogValidationError) {
    if (['name', 'contact', 'email', 'items'].includes(error.code)) {
      return `error.${error.code}`;
    }
    return 'error.unexpected';
  }
  if (error instanceof CatalogHttpError) {
    if (error.status === 404 || error.status === 410) return 'error.notFound';
    if (error.status === 429) return 'error.tooManyAttempts';
    if (error.status >= 500) return 'error.unavailable';
    return 'error.invalidData';
  }
  return 'error.unexpected';
}
