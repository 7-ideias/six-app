import {
  normalizeApiBaseUrl,
  resolvePublicApiConfig,
} from './login-core.mjs';

export const REGISTER_TIMEOUT_MS = 15000;
export const REGISTER_SUCCESS_LOGIN_PATH = '/login';

const REGISTER_ADMIN_PERMISSION = 'ADMINISTRADOR';
const SAFE_BACKEND_ERROR_CODES = Object.freeze([
  'LOG_001',
  'OTP_001',
  'OTP_002',
  'OTP_003',
]);

export const REGISTER_DICTIONARY = Object.freeze({
  pt: Object.freeze({
    title: 'SixApp - Criar conta',
    description: 'Crie sua conta pública no SixApp para organizar vendas, atendimentos, clientes, equipe e financeiro.',
    ogTitle: 'SixApp - Criar conta',
    ogDescription: 'Cadastro público do SixApp para iniciar a gestão do seu comércio.',
    twitterTitle: 'SixApp - Criar conta',
    twitterDescription: 'Comece sua conta no SixApp com login e senha.',
    'access.skip': 'Ir para o formulário de cadastro',
    'brand.aria': 'SixApp',
    'nav.home': 'Voltar para a página inicial',
    'language.aria': 'Selecionar idioma',
    'context.eyebrow': 'Cadastro público',
    'context.title': 'Comece com uma conta de acesso.',
    'context.body': 'O cadastro cria seu usuário administrador e prepara a primeira empresa no SixApp sem autenticar automaticamente.',
    'context.item.one': 'Mesmo contrato público usado pelo fluxo Flutter atual.',
    'context.item.two': 'Nenhum token é salvo durante o cadastro.',
    'context.item.three': 'Depois de criar a conta, o próximo passo é entrar pelo login.',
    'form.title': 'Criar conta no SixApp',
    'form.subtitle': 'Informe um login e uma senha para começar.',
    'form.login.label': 'Login',
    'form.login.placeholder': 'Informe seu login de acesso',
    'form.password.label': 'Senha',
    'form.password.placeholder': 'Mínimo 8 caracteres',
    'form.confirmPassword.label': 'Confirme a senha',
    'form.confirmPassword.placeholder': 'Repita sua senha',
    'form.password.show': 'Mostrar',
    'form.password.hide': 'Ocultar',
    'form.password.showAria': 'Mostrar senha',
    'form.password.hideAria': 'Ocultar senha',
    'form.confirmPassword.showAria': 'Mostrar confirmação da senha',
    'form.confirmPassword.hideAria': 'Ocultar confirmação da senha',
    'form.terms.prefix': 'Concordo com os ',
    'form.terms.link': 'Termos e Condições',
    'form.submit': 'Cadastrar',
    'form.loading': 'Criando conta...',
    'form.login.prompt': 'Já tem uma conta?',
    'form.login.link': 'Entrar',
    'form.compatibility': 'Usar versão compatível',
    'noscript.message': 'Para criar conta por esta página, ative o JavaScript. Você também pode acessar a versão compatível.',
    'noscript.link': 'Usar versão compatível',
    'success.eyebrow': 'Conta criada',
    'success.title': 'Tudo certo!',
    'success.body': 'Sua conta foi criada com sucesso. Faça login para começar a usar o SixApp.',
    'success.login': 'Ir para o login',
    'error.acceptTerms': 'Aceite os Termos e Condições para continuar.',
    'error.fillAllFields': 'Preencha todos os campos.',
    'error.passwordTooShort': 'A senha precisa ter ao menos 8 caracteres.',
    'error.passwordMismatch': 'As senhas não coincidem.',
    'error.passwordsNotEqual': 'As senhas informadas não são iguais. Verifique e tente novamente.',
    'error.config': 'Não foi possível preparar o cadastro seguro. Tente novamente mais tarde.',
    'error.invalidData': 'Revise os dados informados e tente novamente.',
    'error.accountExists': 'Este login ou e-mail já está cadastrado. Faça login ou recupere sua senha.',
    'error.emailNotVerified': 'E-mail não verificado. Confirme o código enviado para prosseguir.',
    'error.invalidOtp': 'Código inválido ou expirado. Solicite um novo código.',
    'error.otpEmailUnavailable': 'Não foi possível enviar o e-mail agora. Tente novamente em instantes.',
    'error.tooManyAttempts': 'Muitas tentativas em sequência. Aguarde alguns minutos e tente novamente.',
    'error.unavailable': 'Serviço temporariamente indisponível. Tente novamente em instantes.',
    'error.timeout': 'A conexão demorou mais do que o esperado. Tente novamente.',
    'error.network': 'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.',
    'error.unexpected': 'Não foi possível criar a conta agora. Tente novamente em instantes.',
    'error.pending': 'Aguarde a tentativa atual terminar.'
  }),
  en: Object.freeze({
    title: 'SixApp - Create Account',
    description: 'Create your public SixApp account to organize sales, service, customers, team and finance.',
    ogTitle: 'SixApp - Create Account',
    ogDescription: 'SixApp public registration to start managing your business.',
    twitterTitle: 'SixApp - Create Account',
    twitterDescription: 'Start your SixApp account with login and password.',
    'access.skip': 'Skip to the registration form',
    'brand.aria': 'SixApp',
    'nav.home': 'Back to the home page',
    'language.aria': 'Select language',
    'context.eyebrow': 'Public registration',
    'context.title': 'Start with an access account.',
    'context.body': 'Registration creates your administrator user and prepares the first company in SixApp without signing you in automatically.',
    'context.item.one': 'Same public contract used by the current Flutter flow.',
    'context.item.two': 'No token is stored during registration.',
    'context.item.three': 'After creating the account, the next step is to sign in.',
    'form.title': 'Create account in SixApp',
    'form.subtitle': 'Enter a login and password to start.',
    'form.login.label': 'Login',
    'form.login.placeholder': 'Enter your access login',
    'form.password.label': 'Password',
    'form.password.placeholder': 'Minimum 8 characters',
    'form.confirmPassword.label': 'Confirm password',
    'form.confirmPassword.placeholder': 'Repeat your password',
    'form.password.show': 'Show',
    'form.password.hide': 'Hide',
    'form.password.showAria': 'Show password',
    'form.password.hideAria': 'Hide password',
    'form.confirmPassword.showAria': 'Show password confirmation',
    'form.confirmPassword.hideAria': 'Hide password confirmation',
    'form.terms.prefix': 'I agree to the ',
    'form.terms.link': 'Terms and Conditions',
    'form.submit': 'Register',
    'form.loading': 'Creating account...',
    'form.login.prompt': 'Already have an account?',
    'form.login.link': 'Sign in',
    'form.compatibility': 'Use compatible version',
    'noscript.message': 'Enable JavaScript to create an account from this page. You can also use the compatible version.',
    'noscript.link': 'Use compatible version',
    'success.eyebrow': 'Account created',
    'success.title': 'All set!',
    'success.body': 'Your account was created successfully. Sign in to start using SixApp.',
    'success.login': 'Go to sign in',
    'error.acceptTerms': 'Accept the Terms and Conditions to continue.',
    'error.fillAllFields': 'Fill in all fields.',
    'error.passwordTooShort': 'The password must have at least 8 characters.',
    'error.passwordMismatch': 'The passwords do not match.',
    'error.passwordsNotEqual': 'The provided passwords are not the same. Review them and try again.',
    'error.config': 'Could not prepare secure registration. Try again later.',
    'error.invalidData': 'Review the information and try again.',
    'error.accountExists': 'This login or email is already registered. Sign in or recover your password.',
    'error.emailNotVerified': 'Email not verified. Confirm the code sent to continue.',
    'error.invalidOtp': 'Invalid or expired code. Request a new code.',
    'error.otpEmailUnavailable': 'Could not send the email right now. Try again shortly.',
    'error.tooManyAttempts': 'Too many attempts in a row. Wait a few minutes and try again.',
    'error.unavailable': 'Service temporarily unavailable. Try again shortly.',
    'error.timeout': 'The connection took longer than expected. Try again.',
    'error.network': 'Could not connect to the server. Check your connection and try again.',
    'error.unexpected': 'Could not create the account right now. Try again shortly.',
    'error.pending': 'Wait for the current attempt to finish.'
  }),
  es: Object.freeze({
    title: 'SixApp - Crear cuenta',
    description: 'Crea tu cuenta pública en SixApp para organizar ventas, atención, clientes, equipo y finanzas.',
    ogTitle: 'SixApp - Crear cuenta',
    ogDescription: 'Registro público de SixApp para iniciar la gestión de tu comercio.',
    twitterTitle: 'SixApp - Crear cuenta',
    twitterDescription: 'Comienza tu cuenta en SixApp con login y contraseña.',
    'access.skip': 'Ir al formulario de registro',
    'brand.aria': 'SixApp',
    'nav.home': 'Volver a la página inicial',
    'language.aria': 'Seleccionar idioma',
    'context.eyebrow': 'Registro público',
    'context.title': 'Comienza con una cuenta de acceso.',
    'context.body': 'El registro crea tu usuario administrador y prepara la primera empresa en SixApp sin iniciar sesión automáticamente.',
    'context.item.one': 'Mismo contrato público usado por el flujo Flutter actual.',
    'context.item.two': 'No se guarda ningún token durante el registro.',
    'context.item.three': 'Después de crear la cuenta, el siguiente paso es entrar por el login.',
    'form.title': 'Crear cuenta en SixApp',
    'form.subtitle': 'Informa un login y una contraseña para comenzar.',
    'form.login.label': 'Login',
    'form.login.placeholder': 'Informa tu login de acceso',
    'form.password.label': 'Contraseña',
    'form.password.placeholder': 'Mínimo 8 caracteres',
    'form.confirmPassword.label': 'Confirma la contraseña',
    'form.confirmPassword.placeholder': 'Repite tu contraseña',
    'form.password.show': 'Mostrar',
    'form.password.hide': 'Ocultar',
    'form.password.showAria': 'Mostrar contraseña',
    'form.password.hideAria': 'Ocultar contraseña',
    'form.confirmPassword.showAria': 'Mostrar confirmación de la contraseña',
    'form.confirmPassword.hideAria': 'Ocultar confirmación de la contraseña',
    'form.terms.prefix': 'Acepto los ',
    'form.terms.link': 'Términos y Condiciones',
    'form.submit': 'Registrar',
    'form.loading': 'Creando cuenta...',
    'form.login.prompt': '¿Ya tienes una cuenta?',
    'form.login.link': 'Entrar',
    'form.compatibility': 'Usar versión compatible',
    'noscript.message': 'Para crear una cuenta por esta página, activa JavaScript. También puedes acceder a la versión compatible.',
    'noscript.link': 'Usar versión compatible',
    'success.eyebrow': 'Cuenta creada',
    'success.title': '¡Todo listo!',
    'success.body': 'Tu cuenta fue creada con éxito. Entra para comenzar a usar SixApp.',
    'success.login': 'Ir al login',
    'error.acceptTerms': 'Acepta los Términos y Condiciones para continuar.',
    'error.fillAllFields': 'Completa todos los campos.',
    'error.passwordTooShort': 'La contraseña debe tener al menos 8 caracteres.',
    'error.passwordMismatch': 'Las contraseñas no coinciden.',
    'error.passwordsNotEqual': 'Las contraseñas informadas no son iguales. Revísalas e intenta nuevamente.',
    'error.config': 'No fue posible preparar el registro seguro. Intenta nuevamente más tarde.',
    'error.invalidData': 'Revisa los datos informados e intenta nuevamente.',
    'error.accountExists': 'Este login o e-mail ya está registrado. Entra o recupera tu contraseña.',
    'error.emailNotVerified': 'E-mail no verificado. Confirma el código enviado para continuar.',
    'error.invalidOtp': 'Código inválido o expirado. Solicita un nuevo código.',
    'error.otpEmailUnavailable': 'No fue posible enviar el e-mail ahora. Intenta nuevamente en instantes.',
    'error.tooManyAttempts': 'Muchas tentativas en secuencia. Espera algunos minutos e intenta nuevamente.',
    'error.unavailable': 'Servicio temporalmente indisponible. Intenta nuevamente en instantes.',
    'error.timeout': 'La conexión tardó más de lo esperado. Intenta nuevamente.',
    'error.network': 'No fue posible conectar al servidor. Verifica tu conexión e intenta nuevamente.',
    'error.unexpected': 'No fue posible crear la cuenta ahora. Intenta nuevamente en instantes.',
    'error.pending': 'Espera a que termine la tentativa actual.'
  })
});

export class PublicRegisterValidationError extends Error {
  constructor(code) {
    super(code);
    this.name = 'PublicRegisterValidationError';
    this.code = code;
  }
}

export class PublicRegisterHttpError extends Error {
  constructor(status, backendCode = null) {
    super(`HTTP ${status}`);
    this.name = 'PublicRegisterHttpError';
    this.status = status;
    this.backendCode = backendCode;
  }
}

export class PublicRegisterTimeoutError extends Error {
  constructor() {
    super('Register request timeout');
    this.name = 'PublicRegisterTimeoutError';
  }
}

export class PublicRegisterNetworkError extends Error {
  constructor() {
    super('Register request network failure');
    this.name = 'PublicRegisterNetworkError';
  }
}

export { resolvePublicApiConfig };

export function createRegisterEndpoint(apiBaseUrl) {
  return `${normalizeApiBaseUrl(apiBaseUrl)}/public/api/login/nova-empresa`;
}

export function normalizeRegisterLogin(value) {
  return String(value || '').trim();
}

export function buildRegisterPayload({
  login,
  senha,
  permissoes = [REGISTER_ADMIN_PERMISSION],
}) {
  const normalizedLogin = normalizeRegisterLogin(login);
  const rawPassword = String(senha || '');
  const payload = {
    login: normalizedLogin,
    username: normalizedLogin,
    senha: rawPassword,
    senhaInicial: rawPassword,
    permissoes: Array.isArray(permissoes) && permissoes.length > 0
      ? [...permissoes]
      : [REGISTER_ADMIN_PERMISSION],
  };

  if (normalizedLogin.includes('@')) {
    payload.email = normalizedLogin;
  }

  return Object.freeze(payload);
}

export function validateRegisterFields({
  login,
  senha,
  confirmarSenha,
  aceitaTermos,
}) {
  if (!aceitaTermos) {
    throw new PublicRegisterValidationError('terms');
  }

  const normalizedLogin = normalizeRegisterLogin(login);
  const rawPassword = String(senha || '');
  const rawConfirmation = String(confirmarSenha || '');

  if (!normalizedLogin || !rawPassword || !rawConfirmation) {
    throw new PublicRegisterValidationError('allFields');
  }

  if (rawPassword.length < 8) {
    throw new PublicRegisterValidationError('passwordTooShort');
  }

  if (rawPassword !== rawConfirmation) {
    throw new PublicRegisterValidationError('passwordMismatch');
  }

  return Object.freeze({
    login: normalizedLogin,
    senha: rawPassword,
  });
}

export function buildRegisterRequest({
  apiBaseUrl,
  login,
  senha,
  confirmarSenha,
  aceitaTermos,
}) {
  const values = validateRegisterFields({
    login,
    senha,
    confirmarSenha,
    aceitaTermos,
  });

  return Object.freeze({
    endpoint: createRegisterEndpoint(apiBaseUrl),
    options: Object.freeze({
      method: 'POST',
      credentials: 'include',
      cache: 'no-store',
      headers: Object.freeze({
        'Content-Type': 'application/json',
        Accept: 'application/json'
      }),
      body: JSON.stringify(buildRegisterPayload(values))
    })
  });
}

export function registerValidationErrorKey(code) {
  if (code === 'terms') return 'error.acceptTerms';
  if (code === 'passwordTooShort') return 'error.passwordTooShort';
  if (code === 'passwordMismatch') return 'error.passwordsNotEqual';
  return 'error.fillAllFields';
}

export function registerErrorKeyForStatus(status, backendCode = null) {
  if (backendCode === 'OTP_001') return 'error.invalidOtp';
  if (backendCode === 'OTP_002') return 'error.otpEmailUnavailable';
  if (backendCode === 'OTP_003') return 'error.emailNotVerified';
  if (status === 400 || status === 422) return 'error.invalidData';
  if (status === 409) return 'error.accountExists';
  if (status === 403) return 'error.emailNotVerified';
  if (status === 429) return 'error.tooManyAttempts';
  if (status === 500 || status === 502 || status === 503 || status === 504) {
    return 'error.unavailable';
  }
  return 'error.unexpected';
}

export function registerErrorKeyFromError(error) {
  if (error instanceof PublicRegisterValidationError) {
    return registerValidationErrorKey(error.code);
  }
  if (error && error.name === 'PublicLoginConfigError') return 'error.config';
  if (error instanceof PublicRegisterHttpError) {
    return registerErrorKeyForStatus(error.status, error.backendCode);
  }
  if (error instanceof PublicRegisterTimeoutError) return 'error.timeout';
  if (error instanceof PublicRegisterNetworkError) return 'error.network';
  return 'error.unexpected';
}

function safeBackendErrorCode(value) {
  const code = String(value || '').trim();
  return SAFE_BACKEND_ERROR_CODES.includes(code) ? code : null;
}

async function extractSafeBackendErrorCode(response) {
  if (!response || typeof response.text !== 'function') return null;

  try {
    const text = await response.text();
    if (!text || text.length > 4096) return null;
    const decoded = JSON.parse(text);
    return safeBackendErrorCode(decoded && decoded.code);
  } catch (_) {
    return null;
  }
}

export async function performPublicRegister({
  apiBaseUrl,
  login,
  senha,
  confirmarSenha,
  aceitaTermos,
  fetchImpl = globalThis.fetch,
  timeoutMs = REGISTER_TIMEOUT_MS,
  AbortControllerClass = globalThis.AbortController,
} = {}) {
  if (typeof fetchImpl !== 'function') {
    throw new PublicRegisterNetworkError();
  }

  const request = buildRegisterRequest({
    apiBaseUrl,
    login,
    senha,
    confirmarSenha,
    aceitaTermos,
  });
  const timeoutDuration =
    Number.isFinite(timeoutMs) && timeoutMs > 0 ? timeoutMs : REGISTER_TIMEOUT_MS;
  const controller =
    typeof AbortControllerClass === 'function'
      ? new AbortControllerClass()
      : null;
  let timeoutId;

  const timeoutPromise = new Promise((_, reject) => {
    timeoutId = setTimeout(() => {
      if (controller) controller.abort();
      reject(new PublicRegisterTimeoutError());
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
    const backendCode = await extractSafeBackendErrorCode(response);
    throw new PublicRegisterHttpError(response ? response.status : 0, backendCode);
  } catch (error) {
    if (
      error instanceof PublicRegisterValidationError ||
      error instanceof PublicRegisterHttpError ||
      error instanceof PublicRegisterTimeoutError ||
      (error && error.name === 'PublicLoginConfigError')
    ) {
      throw error;
    }
    if (error && error.name === 'AbortError') {
      throw new PublicRegisterTimeoutError();
    }
    throw new PublicRegisterNetworkError();
  } finally {
    clearTimeout(timeoutId);
  }
}
