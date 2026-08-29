import {
  normalizeApiBaseUrl,
  resolvePublicApiConfig,
} from './login-core.mjs';

export const COLLABORATOR_INVITE_TIMEOUT_MS = 15000;

export const COLLABORATOR_INVITE_DICTIONARY = Object.freeze({
  pt: Object.freeze({
    title: 'SixoApp - Convite de colaborador',
    description: 'Confirme seu convite de colaborador para acessar uma empresa no SixoApp.',
    ogTitle: 'SixoApp - Convite de colaborador',
    ogDescription: 'Confirme o convite recebido para fazer parte da equipe no SixoApp.',
    twitterTitle: 'SixoApp - Convite de colaborador',
    twitterDescription: 'Confirme o convite recebido para fazer parte da equipe no SixoApp.',
    'access.skip': 'Ir para o convite',
    'brand.aria': 'SixoApp',
    'nav.aria': 'Navegação do convite',
    'nav.home': 'Página inicial',
    'language.aria': 'Selecionar idioma',
    'context.eyebrow': 'Convite para a equipe',
    'context.title': 'Seu próximo acesso começa aqui.',
    'context.body': 'Confirme com segurança o e-mail que recebeu o convite para entrar na equipe de um comércio no SixoApp.',
    'context.security': 'Esta página não exige login e nunca solicita sua senha.',
    'loading.message': 'Validando convite...',
    'error.eyebrow': 'Convite indisponível',
    'error.title': 'Não foi possível carregar o convite',
    'error.retry': 'Tentar novamente',
    'error.home': 'Voltar para a página inicial',
    'invite.eyebrow': 'Convite de colaborador',
    'invite.title': 'Você foi convidado para uma equipe',
    'invite.titleNamed': '{name}, você foi convidado para uma equipe',
    'invite.subtitle': 'Revise os dados do convite e confirme o e-mail que recebeu este link.',
    'invite.summaryAria': 'Resumo do convite',
    'invite.company': 'Comércio',
    'invite.status': 'Status',
    'invite.expires': 'Validade',
    'invite.noPassword': 'O SixoApp não solicitará sua senha nesta confirmação.',
    'status.pending': 'Aguardando confirmação',
    'status.confirmed': 'E-mail confirmado',
    'status.accepted': 'Convite aceito',
    'status.cancelled': 'Convite cancelado',
    'status.expired': 'Convite expirado',
    'status.unknown': 'Em análise',
    'form.email.label': 'E-mail que recebeu o convite',
    'form.email.placeholder': 'exemplo@email.com',
    'form.email.help': 'Use exatamente o endereço informado pelo administrador.',
    'form.submit': 'Confirmar e-mail',
    'form.loading': 'Confirmando...',
    'success.eyebrow': 'E-mail confirmado',
    'success.title': 'Seu acesso foi preparado',
    'success.body': 'O convite foi confirmado. Agora você pode seguir para o login do SixoApp.',
    'success.login': 'Ir para o login',
    'noscript.message': 'Ative o JavaScript para validar e confirmar este convite.',
    'error.invalidLink': 'O link deste convite é inválido. Solicite um novo convite ao administrador.',
    'error.notFound': 'Este convite não foi encontrado. Confira o link recebido ou solicite um novo convite.',
    'error.emailRequired': 'Informe o e-mail que recebeu este convite.',
    'error.emailInvalid': 'Informe um e-mail válido.',
    'error.emailMismatch': 'O e-mail informado não confere com o endereço que recebeu este convite.',
    'error.expired': 'Este convite expirou. Solicite um novo convite ao administrador.',
    'error.used': 'Este convite já foi utilizado.',
    'error.cancelled': 'Este convite foi cancelado. Solicite um novo convite ao administrador.',
    'error.tooManyAttempts': 'Muitas tentativas em sequência. Aguarde alguns minutos e tente novamente.',
    'error.config': 'Não foi possível preparar a confirmação segura. Tente novamente mais tarde.',
    'error.unavailable': 'O serviço está temporariamente indisponível. Tente novamente em instantes.',
    'error.timeout': 'A conexão demorou mais do que o esperado. Tente novamente.',
    'error.network': 'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.',
    'error.unexpected': 'Não foi possível confirmar o convite agora. Tente novamente em instantes.',
    'error.pending': 'Aguarde a confirmação atual terminar.'
  }),
  en: Object.freeze({
    title: 'SixoApp - Collaborator invitation',
    description: 'Confirm your collaborator invitation to access a business in SixoApp.',
    ogTitle: 'SixoApp - Collaborator invitation',
    ogDescription: 'Confirm the invitation you received to join a team in SixoApp.',
    twitterTitle: 'SixoApp - Collaborator invitation',
    twitterDescription: 'Confirm the invitation you received to join a team in SixoApp.',
    'access.skip': 'Skip to the invitation',
    'brand.aria': 'SixoApp',
    'nav.aria': 'Invitation navigation',
    'nav.home': 'Home page',
    'language.aria': 'Select language',
    'context.eyebrow': 'Team invitation',
    'context.title': 'Your next access starts here.',
    'context.body': 'Securely confirm the email address that received the invitation to join a business team in SixoApp.',
    'context.security': 'This page does not require sign-in and never asks for your password.',
    'loading.message': 'Validating invitation...',
    'error.eyebrow': 'Invitation unavailable',
    'error.title': 'The invitation could not be loaded',
    'error.retry': 'Try again',
    'error.home': 'Back to the home page',
    'invite.eyebrow': 'Collaborator invitation',
    'invite.title': 'You were invited to join a team',
    'invite.titleNamed': '{name}, you were invited to join a team',
    'invite.subtitle': 'Review the invitation details and confirm the email address that received this link.',
    'invite.summaryAria': 'Invitation summary',
    'invite.company': 'Business',
    'invite.status': 'Status',
    'invite.expires': 'Expires',
    'invite.noPassword': 'SixoApp will not ask for your password during this confirmation.',
    'status.pending': 'Awaiting confirmation',
    'status.confirmed': 'Email confirmed',
    'status.accepted': 'Invitation accepted',
    'status.cancelled': 'Invitation cancelled',
    'status.expired': 'Invitation expired',
    'status.unknown': 'Under review',
    'form.email.label': 'Email address that received the invitation',
    'form.email.placeholder': 'example@email.com',
    'form.email.help': 'Use the exact address provided by the administrator.',
    'form.submit': 'Confirm email',
    'form.loading': 'Confirming...',
    'success.eyebrow': 'Email confirmed',
    'success.title': 'Your access is ready',
    'success.body': 'The invitation was confirmed. You can now continue to the SixoApp sign-in page.',
    'success.login': 'Go to sign in',
    'noscript.message': 'Enable JavaScript to validate and confirm this invitation.',
    'error.invalidLink': 'This invitation link is invalid. Ask the administrator for a new invitation.',
    'error.notFound': 'This invitation was not found. Check the link or ask for a new invitation.',
    'error.emailRequired': 'Enter the email address that received this invitation.',
    'error.emailInvalid': 'Enter a valid email address.',
    'error.emailMismatch': 'The email address does not match the address that received this invitation.',
    'error.expired': 'This invitation has expired. Ask the administrator for a new invitation.',
    'error.used': 'This invitation has already been used.',
    'error.cancelled': 'This invitation was cancelled. Ask the administrator for a new invitation.',
    'error.tooManyAttempts': 'Too many attempts in a row. Wait a few minutes and try again.',
    'error.config': 'Secure confirmation could not be prepared. Try again later.',
    'error.unavailable': 'The service is temporarily unavailable. Try again shortly.',
    'error.timeout': 'The connection took longer than expected. Try again.',
    'error.network': 'Could not connect to the server. Check your connection and try again.',
    'error.unexpected': 'The invitation could not be confirmed right now. Try again shortly.',
    'error.pending': 'Wait for the current confirmation to finish.'
  }),
  es: Object.freeze({
    title: 'SixoApp - Invitación de colaborador',
    description: 'Confirma tu invitación de colaborador para acceder a un comercio en SixoApp.',
    ogTitle: 'SixoApp - Invitación de colaborador',
    ogDescription: 'Confirma la invitación recibida para formar parte de un equipo en SixoApp.',
    twitterTitle: 'SixoApp - Invitación de colaborador',
    twitterDescription: 'Confirma la invitación recibida para formar parte de un equipo en SixoApp.',
    'access.skip': 'Ir a la invitación',
    'brand.aria': 'SixoApp',
    'nav.aria': 'Navegación de la invitación',
    'nav.home': 'Página inicial',
    'language.aria': 'Seleccionar idioma',
    'context.eyebrow': 'Invitación al equipo',
    'context.title': 'Tu próximo acceso comienza aquí.',
    'context.body': 'Confirma de forma segura el e-mail que recibió la invitación para entrar al equipo de un comercio en SixoApp.',
    'context.security': 'Esta página no requiere inicio de sesión y nunca solicita tu contraseña.',
    'loading.message': 'Validando invitación...',
    'error.eyebrow': 'Invitación no disponible',
    'error.title': 'No fue posible cargar la invitación',
    'error.retry': 'Intentar nuevamente',
    'error.home': 'Volver a la página inicial',
    'invite.eyebrow': 'Invitación de colaborador',
    'invite.title': 'Fuiste invitado a un equipo',
    'invite.titleNamed': '{name}, fuiste invitado a un equipo',
    'invite.subtitle': 'Revisa los datos de la invitación y confirma el e-mail que recibió este enlace.',
    'invite.summaryAria': 'Resumen de la invitación',
    'invite.company': 'Comercio',
    'invite.status': 'Estado',
    'invite.expires': 'Validez',
    'invite.noPassword': 'SixoApp no solicitará tu contraseña durante esta confirmación.',
    'status.pending': 'Esperando confirmación',
    'status.confirmed': 'E-mail confirmado',
    'status.accepted': 'Invitación aceptada',
    'status.cancelled': 'Invitación cancelada',
    'status.expired': 'Invitación expirada',
    'status.unknown': 'En análisis',
    'form.email.label': 'E-mail que recibió la invitación',
    'form.email.placeholder': 'ejemplo@email.com',
    'form.email.help': 'Usa exactamente la dirección informada por el administrador.',
    'form.submit': 'Confirmar e-mail',
    'form.loading': 'Confirmando...',
    'success.eyebrow': 'E-mail confirmado',
    'success.title': 'Tu acceso fue preparado',
    'success.body': 'La invitación fue confirmada. Ahora puedes continuar al inicio de sesión de SixoApp.',
    'success.login': 'Ir al inicio de sesión',
    'noscript.message': 'Activa JavaScript para validar y confirmar esta invitación.',
    'error.invalidLink': 'El enlace de esta invitación es inválido. Solicita una nueva invitación al administrador.',
    'error.notFound': 'Esta invitación no fue encontrada. Revisa el enlace o solicita una nueva invitación.',
    'error.emailRequired': 'Informa el e-mail que recibió esta invitación.',
    'error.emailInvalid': 'Informa un e-mail válido.',
    'error.emailMismatch': 'El e-mail informado no coincide con la dirección que recibió esta invitación.',
    'error.expired': 'Esta invitación expiró. Solicita una nueva invitación al administrador.',
    'error.used': 'Esta invitación ya fue utilizada.',
    'error.cancelled': 'Esta invitación fue cancelada. Solicita una nueva invitación al administrador.',
    'error.tooManyAttempts': 'Muchas tentativas en secuencia. Espera algunos minutos e intenta nuevamente.',
    'error.config': 'No fue posible preparar la confirmación segura. Intenta nuevamente más tarde.',
    'error.unavailable': 'El servicio está temporalmente no disponible. Intenta nuevamente en instantes.',
    'error.timeout': 'La conexión tardó más de lo esperado. Intenta nuevamente.',
    'error.network': 'No fue posible conectar al servidor. Verifica tu conexión e intenta nuevamente.',
    'error.unexpected': 'No fue posible confirmar la invitación ahora. Intenta nuevamente en instantes.',
    'error.pending': 'Espera que termine la confirmación actual.'
  })
});

export class CollaboratorInviteValidationError extends Error {
  constructor(code) {
    super(code);
    this.name = 'CollaboratorInviteValidationError';
    this.code = code;
  }
}

export class CollaboratorInviteHttpError extends Error {
  constructor(status, backendCode = null) {
    super(`HTTP ${status}`);
    this.name = 'CollaboratorInviteHttpError';
    this.status = status;
    this.backendCode = backendCode;
  }
}

export class CollaboratorInviteTimeoutError extends Error {
  constructor() {
    super('Collaborator invitation request timeout');
    this.name = 'CollaboratorInviteTimeoutError';
  }
}

export class CollaboratorInviteNetworkError extends Error {
  constructor() {
    super('Collaborator invitation network failure');
    this.name = 'CollaboratorInviteNetworkError';
  }
}

export { resolvePublicApiConfig };

export function normalizeCollaboratorInviteCode(value) {
  const code = String(value || '').trim();
  if (!/^[A-Za-z0-9_-]{16,128}$/.test(code) || code.toLowerCase() === 'flutter') {
    throw new CollaboratorInviteValidationError('invalidCode');
  }
  return code;
}

export function extractCollaboratorInviteCode(pathname) {
  const segments = String(pathname || '').split('/').filter(Boolean);
  if (
    segments.length !== 3 ||
    segments[0] !== 'colaborador' ||
    segments[1] !== 'convites'
  ) {
    throw new CollaboratorInviteValidationError('invalidCode');
  }

  let decodedCode;
  try {
    decodedCode = decodeURIComponent(segments[2]);
  } catch (_) {
    throw new CollaboratorInviteValidationError('invalidCode');
  }
  return normalizeCollaboratorInviteCode(decodedCode);
}

export function normalizeCollaboratorInviteEmail(value) {
  const email = String(value || '').trim().toLowerCase();
  if (!email) {
    throw new CollaboratorInviteValidationError('emailRequired');
  }
  if (
    email.length > 254 ||
    !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
  ) {
    throw new CollaboratorInviteValidationError('emailInvalid');
  }
  return email;
}

export function createCollaboratorInviteEndpoint(apiBaseUrl, code) {
  return `${normalizeApiBaseUrl(apiBaseUrl)}/public/api/colaborador/convites/${encodeURIComponent(normalizeCollaboratorInviteCode(code))}`;
}

export function createCollaboratorInviteConfirmationEndpoint(apiBaseUrl, code) {
  return `${createCollaboratorInviteEndpoint(apiBaseUrl, code)}/confirmar-email`;
}

export function buildCollaboratorInviteValidationRequest({ apiBaseUrl, code }) {
  return Object.freeze({
    endpoint: createCollaboratorInviteEndpoint(apiBaseUrl, code),
    options: Object.freeze({
      method: 'GET',
      credentials: 'omit',
      cache: 'no-store',
      headers: Object.freeze({ Accept: 'application/json' })
    })
  });
}

export function buildCollaboratorInviteConfirmationRequest({
  apiBaseUrl,
  code,
  email,
}) {
  return Object.freeze({
    endpoint: createCollaboratorInviteConfirmationEndpoint(apiBaseUrl, code),
    options: Object.freeze({
      method: 'POST',
      credentials: 'omit',
      cache: 'no-store',
      headers: Object.freeze({
        'Content-Type': 'application/json',
        Accept: 'application/json'
      }),
      body: JSON.stringify({ email: normalizeCollaboratorInviteEmail(email) })
    })
  });
}

function backendCodeFromPayload(payload, fallbackText = '') {
  const candidates = [
    payload && payload.codigo,
    payload && payload.code,
    payload && payload.message,
    payload && payload.error,
    fallbackText,
  ];
  const knownCodes = [
    'CONVITE_EMAIL_DIVERGENTE',
    'CONVITE_EXPIRADO',
    'CONVITE_JA_UTILIZADO',
    'CONVITE_CANCELADO',
    'CONVITE_NAO_ENCONTRADO',
  ];
  const combined = candidates.filter(Boolean).join(' ').toUpperCase();
  return knownCodes.find((code) => combined.includes(code)) || null;
}

async function parseResponse(response) {
  const text = await response.text();
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch (_) {
    return text;
  }
}

async function performRequest({
  request,
  fetchImpl,
  timeoutMs,
  requirePayload,
}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetchImpl(request.endpoint, {
      ...request.options,
      signal: controller.signal,
    });
    const payload = await parseResponse(response);
    if (!response.ok) {
      const fallbackText = typeof payload === 'string' ? payload : '';
      throw new CollaboratorInviteHttpError(
        response.status,
        backendCodeFromPayload(payload, fallbackText),
      );
    }
    if (requirePayload && (!payload || typeof payload !== 'object')) {
      throw new CollaboratorInviteHttpError(502);
    }
    return payload;
  } catch (error) {
    if (error instanceof CollaboratorInviteHttpError) throw error;
    if (error && error.name === 'AbortError') {
      throw new CollaboratorInviteTimeoutError();
    }
    throw new CollaboratorInviteNetworkError();
  } finally {
    clearTimeout(timeout);
  }
}

export async function fetchCollaboratorInvite({
  apiBaseUrl,
  code,
  fetchImpl = globalThis.fetch,
  timeoutMs = COLLABORATOR_INVITE_TIMEOUT_MS,
}) {
  const payload = await performRequest({
    request: buildCollaboratorInviteValidationRequest({ apiBaseUrl, code }),
    fetchImpl,
    timeoutMs,
    requirePayload: true,
  });
  return Object.freeze({
    emailConvidado: String(payload.emailConvidado || ''),
    nomeConvidado: String(payload.nomeConvidado || ''),
    idUnicoDaEmpresa: String(payload.idUnicoDaEmpresa || ''),
    nomeFantasia: String(payload.nomeFantasia || ''),
    status: String(payload.status || ''),
    expiraEm: String(payload.expiraEm || ''),
  });
}

export async function confirmCollaboratorInviteEmail({
  apiBaseUrl,
  code,
  email,
  fetchImpl = globalThis.fetch,
  timeoutMs = COLLABORATOR_INVITE_TIMEOUT_MS,
}) {
  return performRequest({
    request: buildCollaboratorInviteConfirmationRequest({
      apiBaseUrl,
      code,
      email,
    }),
    fetchImpl,
    timeoutMs,
    requirePayload: false,
  });
}

export function collaboratorInviteStatusKey(value) {
  const status = String(value || '').trim().toUpperCase();
  if (status === 'EMAIL_CONFIRMADO') return 'status.confirmed';
  if (status === 'ACEITO') return 'status.accepted';
  if (status === 'CANCELADO') return 'status.cancelled';
  if (status === 'EXPIRADO') return 'status.expired';
  if (status === 'PENDENTE') return 'status.pending';
  return 'status.unknown';
}

export function collaboratorInviteErrorKeyFromError(error) {
  if (error instanceof CollaboratorInviteValidationError) {
    if (error.code === 'invalidCode') return 'error.invalidLink';
    if (error.code === 'emailRequired') return 'error.emailRequired';
    if (error.code === 'emailInvalid') return 'error.emailInvalid';
  }
  if (error && error.name === 'PublicLoginConfigError') return 'error.config';
  if (error instanceof CollaboratorInviteTimeoutError) return 'error.timeout';
  if (error instanceof CollaboratorInviteNetworkError) return 'error.network';
  if (error instanceof CollaboratorInviteHttpError) {
    if (error.backendCode === 'CONVITE_EMAIL_DIVERGENTE') return 'error.emailMismatch';
    if (error.backendCode === 'CONVITE_EXPIRADO') return 'error.expired';
    if (error.backendCode === 'CONVITE_JA_UTILIZADO') return 'error.used';
    if (error.backendCode === 'CONVITE_CANCELADO') return 'error.cancelled';
    if (error.backendCode === 'CONVITE_NAO_ENCONTRADO') return 'error.notFound';
    if (error.status === 404) return 'error.notFound';
    if (error.status === 410) return 'error.expired';
    if (error.status === 409) return 'error.used';
    if (error.status === 429) return 'error.tooManyAttempts';
    if (error.status >= 500) return 'error.unavailable';
  }
  return 'error.unexpected';
}
