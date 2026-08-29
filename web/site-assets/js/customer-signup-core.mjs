import { normalizeApiBaseUrl, resolvePublicApiConfig } from './login-core.mjs';

export const CUSTOMER_SIGNUP_TIMEOUT_MS = 15000;

const PT = {
  title: 'SixoApp - Cadastro de cliente', description: 'Complete seu cadastro de cliente com segurança no SixoApp.',
  'access.skip': 'Ir para o cadastro', 'brand.aria': 'SixoApp', 'nav.aria': 'Navegação do cadastro', 'nav.home': 'Página inicial', 'language.aria': 'Selecionar idioma',
  'context.eyebrow': 'Cadastro seguro de cliente', 'context.title': 'Seus dados, no seu ritmo.', 'context.body': 'Escolha um cadastro simples ou completo. Você vê a qualidade melhorar enquanto preenche.', 'context.security': 'Esta página não exige login e o link pode ser usado apenas uma vez.',
  'loading.message': 'Validando link...', 'error.eyebrow': 'Link indisponível', 'error.title': 'Não foi possível abrir o cadastro', 'error.retry': 'Tentar novamente', 'error.home': 'Voltar para a página inicial',
  'form.eyebrow': 'Auto cadastro', 'form.title': 'Conte um pouco sobre você', 'form.subtitle': 'Os dados essenciais identificam seu cadastro. Os demais ajudam a empresa a atender melhor.',
  'journey.legend': 'Como deseja preencher?', 'journey.simple.title': 'Cadastro simples', 'journey.simple.body': 'Somente os dados essenciais.', 'journey.complete.title': 'Cadastro completo', 'journey.complete.body': 'Inclui endereço e mais contexto.',
  'quality.title': 'Qualidade do cadastro', 'quality.initial': 'Começando agora', 'quality.essential': 'Base essencial pronta', 'quality.detailed': 'Cadastro bem detalhado', 'quality.excellent': 'Cadastro excelente', 'quality.complete': 'Cadastro excelente. Tudo pronto para enviar.',
  'quality.name': 'Preencha seu nome para começar.', 'quality.document': 'Informe seu documento para identificar o cadastro.', 'quality.phone': 'Adicione um telefone para facilitar o contato.', 'quality.email': 'Adicione um e-mail válido.', 'quality.zip': 'Informe o CEP ou código postal.', 'quality.address': 'Complete o endereço para agilizar entregas.', 'quality.notes': 'Inclua uma observação que ajude no atendimento.',
  'step.essential.simple': 'Etapa 1 de 1 · Essenciais', 'step.essential.complete': 'Etapa 1 de 2 · Essenciais', 'step.details': 'Etapa 2 de 2 · Endereço e contexto',
  'form.personType': 'Tipo de pessoa', 'form.person.pf': 'Pessoa física', 'form.person.pj': 'Pessoa jurídica', 'form.name': 'Nome completo / Razão social', 'form.document': 'CPF/CNPJ', 'form.phone': 'Telefone', 'form.email': 'E-mail', 'form.consent': 'Confirmo que os dados são meus e autorizo seu uso para atendimento e relacionamento com esta empresa.',
  'form.zip': 'CEP / Código postal', 'form.street': 'Logradouro', 'form.number': 'Número', 'form.complement': 'Complemento', 'form.neighborhood': 'Bairro', 'form.city': 'Cidade', 'form.state': 'UF', 'form.notes': 'Observações para atendimento', 'form.continue': 'Continuar', 'form.back': 'Voltar', 'form.submit': 'Concluir cadastro', 'form.loading': 'Enviando...',
  'success.eyebrow': 'Cadastro concluído', 'success.title': 'Seus dados foram enviados', 'success.body': 'A empresa recebeu seu cadastro. Este link não precisa mais ser utilizado.', 'success.home': 'Ir para a página inicial', 'noscript.message': 'Ative o JavaScript para validar e enviar este cadastro.',
  'error.invalidLink': 'Este link de cadastro é inválido. Solicite um novo link à empresa.', 'error.required': 'Preencha nome, documento e aceite a autorização para continuar.', 'error.emailInvalid': 'Informe um e-mail válido.', 'error.expired': 'Este link expirou. Solicite um novo link à empresa.', 'error.used': 'Este link já foi utilizado.', 'error.notFound': 'Este link não foi encontrado. Confira o endereço recebido.', 'error.duplicate': 'Já existe um cliente com este documento nesta empresa.', 'error.rateLimit': 'Muitas tentativas em sequência. Aguarde alguns minutos e tente novamente.', 'error.config': 'Não foi possível preparar o cadastro seguro.', 'error.unavailable': 'O serviço está temporariamente indisponível. Tente novamente em instantes.', 'error.timeout': 'A conexão demorou mais do que o esperado. Tente novamente.', 'error.network': 'Não foi possível conectar ao servidor. Verifique sua conexão.', 'error.unexpected': 'Não foi possível concluir o cadastro agora.', 'error.pending': 'Aguarde o envio atual terminar.'
};

const EN = {
  ...PT, title: 'SixoApp - Customer registration', description: 'Complete your customer registration securely in SixoApp.',
  'access.skip': 'Skip to registration', 'nav.aria': 'Registration navigation', 'nav.home': 'Home page', 'language.aria': 'Select language',
  'context.eyebrow': 'Secure customer registration', 'context.title': 'Your details, at your pace.', 'context.body': 'Choose a simple or complete registration and watch its quality improve as you fill it in.', 'context.security': 'This page does not require sign-in and the link can only be used once.',
  'loading.message': 'Validating link...', 'error.eyebrow': 'Link unavailable', 'error.title': 'Registration could not be opened', 'error.retry': 'Try again', 'error.home': 'Back to the home page',
  'form.eyebrow': 'Self-registration', 'form.title': 'Tell us a little about yourself', 'form.subtitle': 'Essential details identify your profile. The rest helps the business serve you better.',
  'journey.legend': 'How would you like to fill this in?', 'journey.simple.title': 'Simple registration', 'journey.simple.body': 'Essential details only.', 'journey.complete.title': 'Complete registration', 'journey.complete.body': 'Includes address and more context.',
  'quality.title': 'Registration quality', 'quality.initial': 'Just getting started', 'quality.essential': 'Essential profile ready', 'quality.detailed': 'Well-detailed profile', 'quality.excellent': 'Excellent profile', 'quality.complete': 'Excellent profile. Ready to send.',
  'quality.name': 'Enter your name to get started.', 'quality.document': 'Enter your document to identify the profile.', 'quality.phone': 'Add a phone number to make contact easier.', 'quality.email': 'Add a valid email address.', 'quality.zip': 'Add a postal code.', 'quality.address': 'Complete the address to streamline deliveries.', 'quality.notes': 'Add a note that may help with service.',
  'step.essential.simple': 'Step 1 of 1 · Essentials', 'step.essential.complete': 'Step 1 of 2 · Essentials', 'step.details': 'Step 2 of 2 · Address and context',
  'form.personType': 'Person type', 'form.person.pf': 'Individual', 'form.person.pj': 'Business', 'form.name': 'Full name / Legal name', 'form.document': 'Tax ID / Document', 'form.phone': 'Phone', 'form.email': 'Email', 'form.consent': 'I confirm that these details are mine and authorize their use for service and relationship with this business.',
  'form.zip': 'Postal code', 'form.street': 'Street', 'form.number': 'Number', 'form.complement': 'Additional address', 'form.neighborhood': 'District', 'form.city': 'City', 'form.state': 'State', 'form.notes': 'Service notes', 'form.continue': 'Continue', 'form.back': 'Back', 'form.submit': 'Complete registration', 'form.loading': 'Sending...',
  'success.eyebrow': 'Registration complete', 'success.title': 'Your details were sent', 'success.body': 'The business received your registration. This link no longer needs to be used.', 'success.home': 'Go to the home page', 'noscript.message': 'Enable JavaScript to validate and send this registration.',
  'error.invalidLink': 'This registration link is invalid. Ask the business for a new link.', 'error.required': 'Enter your name and document, then accept the authorization.', 'error.emailInvalid': 'Enter a valid email address.', 'error.expired': 'This link has expired. Ask the business for a new link.', 'error.used': 'This link has already been used.', 'error.notFound': 'This link was not found. Check the address you received.', 'error.duplicate': 'A customer with this document already exists in this business.', 'error.rateLimit': 'Too many attempts. Wait a few minutes and try again.', 'error.config': 'Secure registration could not be prepared.', 'error.unavailable': 'The service is temporarily unavailable. Try again shortly.', 'error.timeout': 'The connection took longer than expected.', 'error.network': 'Could not connect to the server. Check your connection.', 'error.unexpected': 'Registration could not be completed right now.', 'error.pending': 'Wait for the current submission to finish.'
};

const ES = {
  ...PT, title: 'SixoApp - Registro de cliente', description: 'Completa tu registro de cliente de forma segura en SixoApp.',
  'access.skip': 'Ir al registro', 'nav.aria': 'Navegación del registro', 'nav.home': 'Página inicial', 'language.aria': 'Seleccionar idioma',
  'context.eyebrow': 'Registro seguro de cliente', 'context.title': 'Tus datos, a tu ritmo.', 'context.body': 'Elige un registro simple o completo y observa cómo mejora su calidad.', 'context.security': 'Esta página no requiere inicio de sesión y el enlace solo puede usarse una vez.',
  'loading.message': 'Validando enlace...', 'error.eyebrow': 'Enlace no disponible', 'error.title': 'No fue posible abrir el registro', 'error.retry': 'Intentar nuevamente', 'error.home': 'Volver a la página inicial',
  'form.eyebrow': 'Auto registro', 'form.title': 'Cuéntanos un poco sobre ti', 'form.subtitle': 'Los datos esenciales identifican tu perfil. Los demás ayudan a la empresa a atenderte mejor.',
  'journey.legend': '¿Cómo deseas completar el registro?', 'journey.simple.title': 'Registro simple', 'journey.simple.body': 'Solo los datos esenciales.', 'journey.complete.title': 'Registro completo', 'journey.complete.body': 'Incluye dirección y más contexto.',
  'quality.title': 'Calidad del registro', 'quality.initial': 'Comenzando ahora', 'quality.essential': 'Perfil esencial listo', 'quality.detailed': 'Perfil bien detallado', 'quality.excellent': 'Perfil excelente', 'quality.complete': 'Perfil excelente. Listo para enviar.',
  'quality.name': 'Informa tu nombre para comenzar.', 'quality.document': 'Informa tu documento para identificar el perfil.', 'quality.phone': 'Agrega un teléfono para facilitar el contacto.', 'quality.email': 'Agrega un correo válido.', 'quality.zip': 'Informa el código postal.', 'quality.address': 'Completa la dirección para agilizar entregas.', 'quality.notes': 'Agrega una observación que ayude en la atención.',
  'step.essential.simple': 'Paso 1 de 1 · Esenciales', 'step.essential.complete': 'Paso 1 de 2 · Esenciales', 'step.details': 'Paso 2 de 2 · Dirección y contexto',
  'form.personType': 'Tipo de persona', 'form.person.pf': 'Persona física', 'form.person.pj': 'Persona jurídica', 'form.name': 'Nombre completo / Razón social', 'form.document': 'Documento fiscal', 'form.phone': 'Teléfono', 'form.email': 'Correo', 'form.consent': 'Confirmo que estos datos son míos y autorizo su uso para la atención y relación con esta empresa.',
  'form.zip': 'Código postal', 'form.street': 'Calle', 'form.number': 'Número', 'form.complement': 'Complemento', 'form.neighborhood': 'Barrio', 'form.city': 'Ciudad', 'form.state': 'Estado', 'form.notes': 'Observaciones para la atención', 'form.continue': 'Continuar', 'form.back': 'Volver', 'form.submit': 'Completar registro', 'form.loading': 'Enviando...',
  'success.eyebrow': 'Registro concluido', 'success.title': 'Tus datos fueron enviados', 'success.body': 'La empresa recibió tu registro. Este enlace ya no necesita ser utilizado.', 'success.home': 'Ir a la página inicial', 'noscript.message': 'Activa JavaScript para validar y enviar este registro.',
  'error.invalidLink': 'Este enlace de registro es inválido. Solicita uno nuevo a la empresa.', 'error.required': 'Informa tu nombre y documento, y acepta la autorización.', 'error.emailInvalid': 'Informa un correo válido.', 'error.expired': 'Este enlace expiró. Solicita uno nuevo a la empresa.', 'error.used': 'Este enlace ya fue utilizado.', 'error.notFound': 'Este enlace no fue encontrado. Revisa la dirección recibida.', 'error.duplicate': 'Ya existe un cliente con este documento en esta empresa.', 'error.rateLimit': 'Demasiados intentos. Espera unos minutos e intenta nuevamente.', 'error.config': 'No fue posible preparar el registro seguro.', 'error.unavailable': 'El servicio no está disponible temporalmente.', 'error.timeout': 'La conexión tardó más de lo esperado.', 'error.network': 'No fue posible conectar al servidor.', 'error.unexpected': 'No fue posible completar el registro ahora.', 'error.pending': 'Espera que termine el envío actual.'
};

export const CUSTOMER_SIGNUP_DICTIONARY = Object.freeze({
  pt: Object.freeze(PT), en: Object.freeze(EN), es: Object.freeze(ES),
});

export class CustomerSignupValidationError extends Error {
  constructor(code) { super(code); this.name = 'CustomerSignupValidationError'; this.code = code; }
}
export class CustomerSignupHttpError extends Error {
  constructor(status, backendCode = null) { super(`HTTP ${status}`); this.name = 'CustomerSignupHttpError'; this.status = status; this.backendCode = backendCode; }
}
export class CustomerSignupTimeoutError extends Error {
  constructor() { super('Customer signup request timeout'); this.name = 'CustomerSignupTimeoutError'; }
}
export class CustomerSignupNetworkError extends Error {
  constructor() { super('Customer signup network failure'); this.name = 'CustomerSignupNetworkError'; }
}

export { resolvePublicApiConfig };

function normalizeIdentifier(value, code) {
  const normalized = String(value || '').trim();
  if (!/^[A-Za-z0-9_-]{8,160}$/.test(normalized) || normalized.toLowerCase() === 'flutter') {
    throw new CustomerSignupValidationError(code);
  }
  return normalized;
}

export function extractCustomerSignupLink(search) {
  const params = new URLSearchParams(String(search || '').replace(/^\?/, ''));
  return Object.freeze({
    token: normalizeIdentifier(params.get('token'), 'invalidLink'),
    companyId: normalizeIdentifier(params.get('idUnicoDaEmpresa'), 'invalidLink'),
    tipoPessoa: String(params.get('tipo') || '').toUpperCase() === 'PJ' ? 'PJ' : 'PF',
    documento: String(params.get('doc') || '').trim().slice(0, 24),
  });
}

function text(value, maxLength) { return String(value || '').trim().slice(0, maxLength); }
function validEmail(value) { return !value || (/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value) && value.length <= 254); }

export function calculateCustomerSignupQuality(values) {
  const complete = values.tipoCadastro === 'COMPLETO';
  const fields = complete
    ? [
        ['name', 20, Boolean(text(values.nome, 160))],
        ['document', 20, Boolean(text(values.documento, 24))],
        ['phone', 15, text(values.telefone, 32).replace(/\D/g, '').length >= 8],
        ['email', 10, Boolean(text(values.email, 254)) && validEmail(text(values.email, 254))],
        ['zip', 10, Boolean(text(values.cep, 16))],
        ['address', 20, ['logradouro', 'numero', 'bairro', 'cidade', 'uf'].every((key) => Boolean(text(values[key], 180)))],
        ['notes', 5, Boolean(text(values.observacoes, 600))],
      ]
    : [
        ['name', 35, Boolean(text(values.nome, 160))],
        ['document', 30, Boolean(text(values.documento, 24))],
        ['phone', 20, text(values.telefone, 32).replace(/\D/g, '').length >= 8],
        ['email', 15, Boolean(text(values.email, 254)) && validEmail(text(values.email, 254))],
      ];
  const percentage = fields.reduce((sum, item) => sum + (item[2] ? item[1] : 0), 0);
  const missing = fields.filter((item) => !item[2]).sort((a, b) => b[1] - a[1]);
  return Object.freeze({ percentage, missing: Object.freeze(missing.map((item) => item[0])) });
}

export function buildCustomerSignupPayload(values, link) {
  const tipoCadastro = values.tipoCadastro === 'COMPLETO' ? 'COMPLETO' : 'SIMPLES';
  const nome = text(values.nome, 160);
  const documento = text(values.documento, 24);
  const email = text(values.email, 254).toLowerCase();
  if (!nome || !documento || values.consentimento !== true) throw new CustomerSignupValidationError('required');
  if (!validEmail(email)) throw new CustomerSignupValidationError('emailInvalid');
  const payload = {
    idUnicoDaEmpresa: link.companyId, token: link.token, tipoCadastro,
    percentualQualidadeCadastro: calculateCustomerSignupQuality(values).percentage,
    tipoPessoa: values.tipoPessoa === 'PJ' ? 'PJ' : 'PF', documento, nome,
    telefone: text(values.telefone, 32), email,
    cep: tipoCadastro === 'COMPLETO' ? text(values.cep, 16) : '',
    logradouro: tipoCadastro === 'COMPLETO' ? text(values.logradouro, 180) : '',
    numero: tipoCadastro === 'COMPLETO' ? text(values.numero, 24) : '',
    complemento: tipoCadastro === 'COMPLETO' ? text(values.complemento, 100) : '',
    bairro: tipoCadastro === 'COMPLETO' ? text(values.bairro, 100) : '',
    cidade: tipoCadastro === 'COMPLETO' ? text(values.cidade, 100) : '',
    uf: tipoCadastro === 'COMPLETO' ? text(values.uf, 3).toUpperCase() : '',
    observacoes: tipoCadastro === 'COMPLETO' ? text(values.observacoes, 600) : '',
    origem: 'PUBLIC_HTML', enviadoEm: new Date().toISOString(),
  };
  payload.enderecoCompleto = [payload.logradouro, payload.numero, payload.complemento, payload.bairro, payload.cidade, payload.uf, payload.cep].filter(Boolean).join(', ');
  return Object.freeze(payload);
}

export function buildCustomerSignupValidationRequest({ apiBaseUrl, link }) {
  const base = normalizeApiBaseUrl(apiBaseUrl);
  return Object.freeze({ endpoint: `${base}/public/api/auto-customer/token?idUnicoDaEmpresa=${encodeURIComponent(link.companyId)}&token=${encodeURIComponent(link.token)}`, options: Object.freeze({ method: 'GET', credentials: 'omit', cache: 'no-store', headers: Object.freeze({ Accept: 'application/json' }) }) });
}

export function buildCustomerSignupRequest({ apiBaseUrl, link, values }) {
  return Object.freeze({ endpoint: `${normalizeApiBaseUrl(apiBaseUrl)}/public/api/auto-customer`, options: Object.freeze({ method: 'POST', credentials: 'omit', cache: 'no-store', headers: Object.freeze({ 'Content-Type': 'application/json', Accept: 'application/json', idUnicoDaEmpresa: link.companyId }), body: JSON.stringify(buildCustomerSignupPayload(values, link)) }) });
}

async function requestJson(request, fetchImpl, timeoutMs) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetchImpl(request.endpoint, { ...request.options, signal: controller.signal });
    const raw = await response.text();
    let payload = null;
    try { payload = raw ? JSON.parse(raw) : null; } catch (_) { payload = null; }
    if (!response.ok) throw new CustomerSignupHttpError(response.status, payload && payload.code);
    return payload;
  } catch (error) {
    if (error instanceof CustomerSignupHttpError) throw error;
    if (error && error.name === 'AbortError') throw new CustomerSignupTimeoutError();
    if (error instanceof TypeError) throw new CustomerSignupNetworkError();
    throw error;
  } finally { clearTimeout(timeout); }
}

export function validateCustomerSignupLink({ apiBaseUrl, link, fetchImpl = fetch, timeoutMs = CUSTOMER_SIGNUP_TIMEOUT_MS }) {
  return requestJson(buildCustomerSignupValidationRequest({ apiBaseUrl, link }), fetchImpl, timeoutMs);
}
export function submitCustomerSignup({ apiBaseUrl, link, values, fetchImpl = fetch, timeoutMs = CUSTOMER_SIGNUP_TIMEOUT_MS }) {
  return requestJson(buildCustomerSignupRequest({ apiBaseUrl, link, values }), fetchImpl, timeoutMs);
}

export function customerSignupErrorKey(error) {
  if (error instanceof CustomerSignupValidationError) return `error.${error.code}`;
  if (error instanceof CustomerSignupTimeoutError) return 'error.timeout';
  if (error instanceof CustomerSignupNetworkError) return 'error.network';
  if (error instanceof CustomerSignupHttpError) {
    const code = String(error.backendCode || '').toUpperCase();
    if (code.includes('EXPIRED')) return 'error.expired';
    if (code.includes('USED')) return 'error.used';
    if (code.includes('NOT_FOUND') || code.includes('INVALID_TOKEN')) return 'error.notFound';
    if (code.includes('ALREADY_EXISTS')) return 'error.duplicate';
    if (error.status === 429) return 'error.rateLimit';
    if (error.status >= 500) return 'error.unavailable';
    if (error.status === 404) return 'error.notFound';
  }
  return 'error.unexpected';
}
