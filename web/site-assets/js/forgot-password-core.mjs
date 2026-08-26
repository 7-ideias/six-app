import {
  normalizeApiBaseUrl,
  resolvePublicApiConfig,
} from './login-core.mjs';

export const FORGOT_PASSWORD_TIMEOUT_MS = 15000;
export const FORGOT_PASSWORD_RESEND_COOLDOWN_SECONDS = 45;
export const FORGOT_PASSWORD_SUCCESS_LOGIN_PATH = '/login';

const SAFE_BACKEND_ERROR_CODES = Object.freeze([
  'AGF_005',
  'OTP_001',
  'OTP_002',
  'OTP_003',
  'PWD_001',
  'PWD_002',
  'PWD_003',
  'PWD_004',
  'PWD_005',
]);

export const FORGOT_PASSWORD_DICTIONARY = Object.freeze({
  pt: Object.freeze({
    title: 'SixoApp - Recuperar senha',
    description: 'Recupere o acesso ao SixoApp com o código enviado ao seu e-mail cadastrado.',
    ogTitle: 'SixoApp - Recuperar senha',
    ogDescription: 'Fluxo público de recuperação de senha do SixoApp.',
    twitterTitle: 'SixoApp - Recuperar senha',
    twitterDescription: 'Receba um código e defina uma nova senha para acessar o SixoApp.',
    'access.skip': 'Ir para o formulário de recuperação',
    'brand.aria': 'SixoApp',
    'nav.home': 'Voltar para a página inicial',
    'nav.login': 'Voltar para o login',
    'language.aria': 'Selecionar idioma',
    'context.eyebrow': 'Recuperação de acesso',
    'context.title': 'Defina uma nova senha com segurança.',
    'context.body': 'Use o e-mail cadastrado, confirme o código recebido e escolha uma nova senha para voltar ao login.',
    'context.item.one': 'Seu código é enviado apenas para o e-mail cadastrado.',
    'context.item.two': 'A validação acontece em uma etapa protegida.',
    'context.item.three': 'Sua nova senha entra em vigor assim que confirmada.',
    'form.eyebrow': 'Acesso à conta',
    'progress.aria': 'Progresso da recuperação',
    'step.identify': 'E-mail',
    'step.code': 'Código',
    'step.password': 'Nova senha',
    'identify.title': 'Recuperar senha',
    'identify.subtitle': 'Informe seu e-mail para receber o código de recuperação.',
    'identify.submit': 'Enviar código de recuperação',
    'identify.loading': 'Enviando código...',
    'email.label': 'E-mail',
    'email.placeholder': 'Informe seu e-mail cadastrado',
    'code.title': 'Confirmar código',
    'code.subtitle': 'Digite o código de 6 dígitos enviado ao e-mail informado.',
    'code.label': 'Código de 6 dígitos',
    'code.placeholder': '000000',
    'code.help': 'Digite somente os números do código recebido.',
    'code.submit': 'Verificar código',
    'code.loading': 'Verificando código...',
    'password.title': 'Nova senha',
    'password.subtitle': 'Defina a nova senha da sua conta.',
    'password.label': 'Nova senha',
    'password.placeholder': 'Mínimo 8 caracteres',
    'password.submit': 'Redefinir senha',
    'password.loading': 'Redefinindo senha...',
    'password.show': 'Mostrar',
    'password.hide': 'Ocultar',
    'password.showAria': 'Mostrar senha',
    'password.hideAria': 'Ocultar senha',
    'confirmPassword.label': 'Confirme a senha',
    'confirmPassword.placeholder': 'Repita sua nova senha',
    'confirmPassword.showAria': 'Mostrar confirmação da senha',
    'confirmPassword.hideAria': 'Ocultar confirmação da senha',
    'action.backEmail': 'Alterar e-mail',
    'action.backCode': 'Voltar ao código',
    'action.resend': 'Reenviar código',
    'action.resendLoading': 'Reenviando...',
    'action.resendCountdown': 'Reenviar em {seconds}s',
    'footer.login.prompt': 'Lembrou sua senha?',
    'footer.login.link': 'Voltar para o login',
    'footer.compatibility': 'Usar versão compatível',
    'noscript.message': 'Para recuperar a senha por esta página, ative o JavaScript. Você também pode acessar a versão compatível.',
    'noscript.link': 'Usar versão compatível',
    'success.eyebrow': 'Senha alterada',
    'success.title': 'Senha redefinida com sucesso.',
    'success.body': 'Use sua nova senha para entrar no SixoApp.',
    'success.login': 'Ir para o login',
    'info.instructionsSent': 'Se os dados informados estiverem cadastrados, enviaremos as instruções para recuperação.',
    'info.codeAccepted': 'Código validado. Agora defina sua nova senha.',
    'info.resendSent': 'Se os dados informados estiverem cadastrados, enviaremos um novo código.',
    'error.requiredEmail': 'Informe seu e-mail.',
    'error.requiredCode': 'Informe o código recebido.',
    'error.codeFormat': 'Digite os 6 dígitos do código.',
    'error.requiredPassword': 'Preencha a nova senha e a confirmação.',
    'error.passwordTooShort': 'A senha precisa ter ao menos 8 caracteres.',
    'error.passwordTooLong': 'A senha deve ter no máximo 64 caracteres.',
    'error.passwordMismatch': 'As senhas não coincidem.',
    'error.stateMissing': 'Reinicie a recuperação para continuar.',
    'error.config': 'Não foi possível preparar a recuperação segura. Tente novamente mais tarde.',
    'error.invalidData': 'Revise os dados informados e tente novamente.',
    'error.codeInvalid': 'Código inválido ou expirado. Verifique os dígitos ou solicite um novo código.',
    'error.codeExpired': 'Código expirado. Solicite um novo código.',
    'error.codeNotVerified': 'Confirme o código enviado antes de redefinir a senha.',
    'error.passwordInvalid': 'A nova senha não atende aos requisitos mínimos.',
    'error.recoveryNotCompleted': 'Não foi possível concluir a redefinição com os dados informados.',
    'error.emailUnavailable': 'Não foi possível enviar o e-mail agora. Tente novamente em instantes.',
    'error.tooManyAttempts': 'Muitas tentativas em sequência. Aguarde alguns minutos e tente novamente.',
    'error.unavailable': 'Serviço temporariamente indisponível. Tente novamente em instantes.',
    'error.timeout': 'A conexão demorou mais do que o esperado. Tente novamente.',
    'error.network': 'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.',
    'error.unexpected': 'Não foi possível concluir a recuperação agora. Tente novamente em instantes.',
    'error.pending': 'Aguarde a tentativa atual terminar.'
  }),
  en: Object.freeze({
    title: 'SixoApp - Recover Password',
    description: 'Recover access to SixoApp with the code sent to your registered email.',
    ogTitle: 'SixoApp - Recover Password',
    ogDescription: 'SixoApp public password recovery flow.',
    twitterTitle: 'SixoApp - Recover Password',
    twitterDescription: 'Receive a code and set a new password to access SixoApp.',
    'access.skip': 'Skip to the recovery form',
    'brand.aria': 'SixoApp',
    'nav.home': 'Back to the home page',
    'nav.login': 'Back to sign in',
    'language.aria': 'Select language',
    'context.eyebrow': 'Access recovery',
    'context.title': 'Set a new password securely.',
    'context.body': 'Use the registered email, confirm the received code and choose a new password to return to sign in.',
    'context.item.one': 'Your code is sent only to the registered email.',
    'context.item.two': 'Validation takes place in a protected step.',
    'context.item.three': 'Your new password takes effect as soon as it is confirmed.',
    'form.eyebrow': 'Account access',
    'progress.aria': 'Recovery progress',
    'step.identify': 'Email',
    'step.code': 'Code',
    'step.password': 'New password',
    'identify.title': 'Recover password',
    'identify.subtitle': 'Enter your email to receive the recovery code.',
    'identify.submit': 'Send recovery code',
    'identify.loading': 'Sending code...',
    'email.label': 'Email',
    'email.placeholder': 'Enter your registered email',
    'code.title': 'Confirm code',
    'code.subtitle': 'Enter the 6-digit code sent to the provided email.',
    'code.label': '6-digit code',
    'code.placeholder': '000000',
    'code.help': 'Enter only the numbers from the received code.',
    'code.submit': 'Verify code',
    'code.loading': 'Verifying code...',
    'password.title': 'New password',
    'password.subtitle': 'Set the new password for your account.',
    'password.label': 'New password',
    'password.placeholder': 'Minimum 8 characters',
    'password.submit': 'Reset password',
    'password.loading': 'Resetting password...',
    'password.show': 'Show',
    'password.hide': 'Hide',
    'password.showAria': 'Show password',
    'password.hideAria': 'Hide password',
    'confirmPassword.label': 'Confirm password',
    'confirmPassword.placeholder': 'Repeat your new password',
    'confirmPassword.showAria': 'Show password confirmation',
    'confirmPassword.hideAria': 'Hide password confirmation',
    'action.backEmail': 'Change email',
    'action.backCode': 'Back to code',
    'action.resend': 'Resend code',
    'action.resendLoading': 'Resending...',
    'action.resendCountdown': 'Resend in {seconds}s',
    'footer.login.prompt': 'Remembered your password?',
    'footer.login.link': 'Back to sign in',
    'footer.compatibility': 'Use compatible version',
    'noscript.message': 'Enable JavaScript to recover your password from this page. You can also use the compatible version.',
    'noscript.link': 'Use compatible version',
    'success.eyebrow': 'Password changed',
    'success.title': 'Password reset successfully.',
    'success.body': 'Use your new password to sign in to SixoApp.',
    'success.login': 'Go to sign in',
    'info.instructionsSent': 'If the provided information is registered, we will send recovery instructions.',
    'info.codeAccepted': 'Code verified. Now set your new password.',
    'info.resendSent': 'If the provided information is registered, we will send a new code.',
    'error.requiredEmail': 'Enter your email.',
    'error.requiredCode': 'Enter the received code.',
    'error.codeFormat': 'Enter the 6 digits of the code.',
    'error.requiredPassword': 'Fill in the new password and confirmation.',
    'error.passwordTooShort': 'The password must have at least 8 characters.',
    'error.passwordTooLong': 'The password must have at most 64 characters.',
    'error.passwordMismatch': 'The passwords do not match.',
    'error.stateMissing': 'Restart recovery to continue.',
    'error.config': 'Could not prepare secure recovery. Try again later.',
    'error.invalidData': 'Review the information and try again.',
    'error.codeInvalid': 'Invalid or expired code. Check the digits or request a new code.',
    'error.codeExpired': 'Code expired. Request a new code.',
    'error.codeNotVerified': 'Confirm the sent code before resetting the password.',
    'error.passwordInvalid': 'The new password does not meet the minimum requirements.',
    'error.recoveryNotCompleted': 'Could not complete the reset with the provided information.',
    'error.emailUnavailable': 'Could not send the email right now. Try again shortly.',
    'error.tooManyAttempts': 'Too many attempts in a row. Wait a few minutes and try again.',
    'error.unavailable': 'Service temporarily unavailable. Try again shortly.',
    'error.timeout': 'The connection took longer than expected. Try again.',
    'error.network': 'Could not connect to the server. Check your connection and try again.',
    'error.unexpected': 'Could not complete recovery right now. Try again shortly.',
    'error.pending': 'Wait for the current attempt to finish.'
  }),
  es: Object.freeze({
    title: 'SixoApp - Recuperar contraseña',
    description: 'Recupera el acceso a SixoApp con el código enviado a tu e-mail registrado.',
    ogTitle: 'SixoApp - Recuperar contraseña',
    ogDescription: 'Flujo público de recuperación de contraseña de SixoApp.',
    twitterTitle: 'SixoApp - Recuperar contraseña',
    twitterDescription: 'Recibe un código y define una nueva contraseña para acceder a SixoApp.',
    'access.skip': 'Ir al formulario de recuperación',
    'brand.aria': 'SixoApp',
    'nav.home': 'Volver a la página inicial',
    'nav.login': 'Volver al login',
    'language.aria': 'Seleccionar idioma',
    'context.eyebrow': 'Recuperación de acceso',
    'context.title': 'Define una nueva contraseña con seguridad.',
    'context.body': 'Usa el e-mail registrado, confirma el código recibido y elige una nueva contraseña para volver al login.',
    'context.item.one': 'Tu código se envía solo al e-mail registrado.',
    'context.item.two': 'La validación se realiza en una etapa protegida.',
    'context.item.three': 'Tu nueva contraseña entra en vigor al ser confirmada.',
    'form.eyebrow': 'Acceso a la cuenta',
    'progress.aria': 'Progreso de la recuperación',
    'step.identify': 'E-mail',
    'step.code': 'Código',
    'step.password': 'Nueva contraseña',
    'identify.title': 'Recuperar contraseña',
    'identify.subtitle': 'Informa tu e-mail para recibir el código de recuperación.',
    'identify.submit': 'Enviar código de recuperación',
    'identify.loading': 'Enviando código...',
    'email.label': 'E-mail',
    'email.placeholder': 'Informa tu e-mail registrado',
    'code.title': 'Confirmar código',
    'code.subtitle': 'Ingresa el código de 6 dígitos enviado al e-mail informado.',
    'code.label': 'Código de 6 dígitos',
    'code.placeholder': '000000',
    'code.help': 'Ingresa solo los números del código recibido.',
    'code.submit': 'Verificar código',
    'code.loading': 'Verificando código...',
    'password.title': 'Nueva contraseña',
    'password.subtitle': 'Define la nueva contraseña de tu cuenta.',
    'password.label': 'Nueva contraseña',
    'password.placeholder': 'Mínimo 8 caracteres',
    'password.submit': 'Restablecer contraseña',
    'password.loading': 'Restableciendo contraseña...',
    'password.show': 'Mostrar',
    'password.hide': 'Ocultar',
    'password.showAria': 'Mostrar contraseña',
    'password.hideAria': 'Ocultar contraseña',
    'confirmPassword.label': 'Confirma la contraseña',
    'confirmPassword.placeholder': 'Repite tu nueva contraseña',
    'confirmPassword.showAria': 'Mostrar confirmación de la contraseña',
    'confirmPassword.hideAria': 'Ocultar confirmación de la contraseña',
    'action.backEmail': 'Cambiar e-mail',
    'action.backCode': 'Volver al código',
    'action.resend': 'Reenviar código',
    'action.resendLoading': 'Reenviando...',
    'action.resendCountdown': 'Reenviar en {seconds}s',
    'footer.login.prompt': '¿Recordaste tu contraseña?',
    'footer.login.link': 'Volver al login',
    'footer.compatibility': 'Usar versión compatible',
    'noscript.message': 'Para recuperar la contraseña por esta página, activa JavaScript. También puedes acceder a la versión compatible.',
    'noscript.link': 'Usar versión compatible',
    'success.eyebrow': 'Contraseña cambiada',
    'success.title': 'Contraseña restablecida con éxito.',
    'success.body': 'Usa tu nueva contraseña para entrar en SixoApp.',
    'success.login': 'Ir al login',
    'info.instructionsSent': 'Si los datos informados están registrados, enviaremos las instrucciones de recuperación.',
    'info.codeAccepted': 'Código validado. Ahora define tu nueva contraseña.',
    'info.resendSent': 'Si los datos informados están registrados, enviaremos un nuevo código.',
    'error.requiredEmail': 'Informa tu e-mail.',
    'error.requiredCode': 'Informa el código recibido.',
    'error.codeFormat': 'Ingresa los 6 dígitos del código.',
    'error.requiredPassword': 'Completa la nueva contraseña y la confirmación.',
    'error.passwordTooShort': 'La contraseña debe tener al menos 8 caracteres.',
    'error.passwordTooLong': 'La contraseña debe tener como máximo 64 caracteres.',
    'error.passwordMismatch': 'Las contraseñas no coinciden.',
    'error.stateMissing': 'Reinicia la recuperación para continuar.',
    'error.config': 'No fue posible preparar la recuperación segura. Intenta nuevamente más tarde.',
    'error.invalidData': 'Revisa los datos informados e intenta nuevamente.',
    'error.codeInvalid': 'Código inválido o expirado. Revisa los dígitos o solicita un nuevo código.',
    'error.codeExpired': 'Código expirado. Solicita un nuevo código.',
    'error.codeNotVerified': 'Confirma el código enviado antes de restablecer la contraseña.',
    'error.passwordInvalid': 'La nueva contraseña no cumple los requisitos mínimos.',
    'error.recoveryNotCompleted': 'No fue posible completar el restablecimiento con los datos informados.',
    'error.emailUnavailable': 'No fue posible enviar el e-mail ahora. Intenta nuevamente en instantes.',
    'error.tooManyAttempts': 'Muchas tentativas en secuencia. Espera algunos minutos e intenta nuevamente.',
    'error.unavailable': 'Servicio temporalmente indisponible. Intenta nuevamente en instantes.',
    'error.timeout': 'La conexión tardó más de lo esperado. Intenta nuevamente.',
    'error.network': 'No fue posible conectar al servidor. Verifica tu conexión e intenta nuevamente.',
    'error.unexpected': 'No fue posible completar la recuperación ahora. Intenta nuevamente en instantes.',
    'error.pending': 'Espera a que termine la tentativa actual.'
  })
});

export class PublicForgotPasswordValidationError extends Error {
  constructor(code) {
    super(code);
    this.name = 'PublicForgotPasswordValidationError';
    this.code = code;
  }
}

export class PublicForgotPasswordHttpError extends Error {
  constructor(status, action, backendCode = null) {
    super(`HTTP ${status}`);
    this.name = 'PublicForgotPasswordHttpError';
    this.status = status;
    this.action = action;
    this.backendCode = backendCode;
  }
}

export class PublicForgotPasswordTimeoutError extends Error {
  constructor() {
    super('Forgot password request timeout');
    this.name = 'PublicForgotPasswordTimeoutError';
  }
}

export class PublicForgotPasswordNetworkError extends Error {
  constructor() {
    super('Forgot password request network failure');
    this.name = 'PublicForgotPasswordNetworkError';
  }
}

export { resolvePublicApiConfig };

export function createSendCodeEndpoint(apiBaseUrl) {
  return `${normalizeApiBaseUrl(apiBaseUrl)}/public/api/esqueceu-senha/enviar-codigo`;
}

export function createValidateCodeEndpoint(apiBaseUrl) {
  return `${normalizeApiBaseUrl(apiBaseUrl)}/public/api/esqueceu-senha/validar-codigo`;
}

export function createResetPasswordEndpoint(apiBaseUrl) {
  return `${normalizeApiBaseUrl(apiBaseUrl)}/public/api/esqueceu-senha/redefinir-senha`;
}

export function normalizeRecoveryEmail(value) {
  return String(value || '').trim();
}

export function normalizeRecoveryCode(value) {
  return String(value || '').replace(/\D/g, '').slice(0, 6);
}

export function normalizeRecoveryPassword(value) {
  return String(value || '').trim();
}

export function validateRecoveryEmail(email) {
  const normalizedEmail = normalizeRecoveryEmail(email);
  if (!normalizedEmail) {
    throw new PublicForgotPasswordValidationError('email');
  }
  return normalizedEmail;
}

export function validateRecoveryCode(codigo) {
  const normalizedCode = normalizeRecoveryCode(codigo);
  if (!String(codigo || '').trim()) {
    throw new PublicForgotPasswordValidationError('codeRequired');
  }
  if (!/^\d{6}$/.test(normalizedCode)) {
    throw new PublicForgotPasswordValidationError('codeFormat');
  }
  return normalizedCode;
}

export function validateRecoveryPasswordFields({
  novaSenha,
  confirmarSenha,
}) {
  const password = normalizeRecoveryPassword(novaSenha);
  const confirmation = normalizeRecoveryPassword(confirmarSenha);

  if (!password || !confirmation) {
    throw new PublicForgotPasswordValidationError('passwordRequired');
  }
  if (password.length < 8) {
    throw new PublicForgotPasswordValidationError('passwordTooShort');
  }
  if (password.length > 64) {
    throw new PublicForgotPasswordValidationError('passwordTooLong');
  }
  if (password !== confirmation) {
    throw new PublicForgotPasswordValidationError('passwordMismatch');
  }

  return Object.freeze({ novaSenha: password });
}

function buildJsonPostRequest(endpoint, payload) {
  return Object.freeze({
    endpoint,
    options: Object.freeze({
      method: 'POST',
      credentials: 'include',
      cache: 'no-store',
      headers: Object.freeze({
        'Content-Type': 'application/json',
        Accept: 'application/json'
      }),
      body: JSON.stringify(payload)
    })
  });
}

export function buildSendCodeRequest({ apiBaseUrl, email }) {
  const normalizedEmail = validateRecoveryEmail(email);
  return buildJsonPostRequest(
    createSendCodeEndpoint(apiBaseUrl),
    { email: normalizedEmail },
  );
}

export function buildValidateCodeRequest({ apiBaseUrl, email, codigo }) {
  const normalizedEmail = validateRecoveryEmail(email);
  const normalizedCode = validateRecoveryCode(codigo);
  return buildJsonPostRequest(
    createValidateCodeEndpoint(apiBaseUrl),
    { email: normalizedEmail, codigo: normalizedCode },
  );
}

export function buildResetPasswordRequest({
  apiBaseUrl,
  email,
  codigo,
  novaSenha,
  confirmarSenha,
}) {
  const normalizedEmail = validateRecoveryEmail(email);
  const normalizedCode = validateRecoveryCode(codigo);
  const passwordValues = validateRecoveryPasswordFields({
    novaSenha,
    confirmarSenha,
  });
  return buildJsonPostRequest(
    createResetPasswordEndpoint(apiBaseUrl),
    {
      email: normalizedEmail,
      codigo: normalizedCode,
      novaSenha: passwordValues.novaSenha
    },
  );
}

export function forgotPasswordValidationErrorKey(code) {
  if (code === 'email') return 'error.requiredEmail';
  if (code === 'codeRequired') return 'error.requiredCode';
  if (code === 'codeFormat') return 'error.codeFormat';
  if (code === 'passwordRequired') return 'error.requiredPassword';
  if (code === 'passwordTooShort') return 'error.passwordTooShort';
  if (code === 'passwordTooLong') return 'error.passwordTooLong';
  if (code === 'passwordMismatch') return 'error.passwordMismatch';
  return 'error.stateMissing';
}

export function isNeutralSendCodeStatus(status, backendCode = null) {
  return status === 404 ||
    status === 409 ||
    backendCode === 'PWD_001';
}

export function forgotPasswordErrorKeyForStatus(
  status,
  backendCode = null,
  action = 'send',
) {
  if (action === 'send' && isNeutralSendCodeStatus(status, backendCode)) {
    return 'info.instructionsSent';
  }
  if (backendCode === 'OTP_001' || backendCode === 'PWD_002') {
    return 'error.codeInvalid';
  }
  if (backendCode === 'PWD_003') return 'error.codeExpired';
  if (backendCode === 'OTP_002' || backendCode === 'PWD_004') {
    return 'error.emailUnavailable';
  }
  if (backendCode === 'OTP_003') return 'error.codeNotVerified';
  if (backendCode === 'PWD_005') return 'error.passwordInvalid';
  if (backendCode === 'PWD_001') return 'error.recoveryNotCompleted';

  if (status === 400) return 'error.invalidData';
  if (status === 401) return 'error.codeInvalid';
  if (status === 403) return 'error.codeNotVerified';
  if (status === 404) return 'error.recoveryNotCompleted';
  if (status === 410) return 'error.codeExpired';
  if (status === 422) return 'error.passwordInvalid';
  if (status === 429) return 'error.tooManyAttempts';
  if (status === 500 || status === 502 || status === 503 || status === 504) {
    return 'error.unavailable';
  }
  return 'error.unexpected';
}

export function forgotPasswordErrorKeyFromError(error) {
  if (error instanceof PublicForgotPasswordValidationError) {
    return forgotPasswordValidationErrorKey(error.code);
  }
  if (error && error.name === 'PublicLoginConfigError') return 'error.config';
  if (error instanceof PublicForgotPasswordHttpError) {
    return forgotPasswordErrorKeyForStatus(
      error.status,
      error.backendCode,
      error.action,
    );
  }
  if (error instanceof PublicForgotPasswordTimeoutError) {
    return 'error.timeout';
  }
  if (error instanceof PublicForgotPasswordNetworkError) {
    return 'error.network';
  }
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
    return safeBackendErrorCode(decoded && (decoded.code || decoded.codigo));
  } catch (_) {
    return null;
  }
}

async function performForgotPasswordRequest({
  request,
  action,
  fetchImpl,
  timeoutMs,
  AbortControllerClass,
}) {
  if (typeof fetchImpl !== 'function') {
    throw new PublicForgotPasswordNetworkError();
  }

  const timeoutDuration =
    Number.isFinite(timeoutMs) && timeoutMs > 0
      ? timeoutMs
      : FORGOT_PASSWORD_TIMEOUT_MS;
  const controller =
    typeof AbortControllerClass === 'function'
      ? new AbortControllerClass()
      : null;
  let timeoutId;

  const timeoutPromise = new Promise((_, reject) => {
    timeoutId = setTimeout(() => {
      if (controller) controller.abort();
      reject(new PublicForgotPasswordTimeoutError());
    }, timeoutDuration);
  });

  const fetchPromise = fetchImpl(request.endpoint, {
    ...request.options,
    signal: controller ? controller.signal : undefined,
  });

  try {
    const response = await Promise.race([fetchPromise, timeoutPromise]);
    if (response && response.ok) {
      return Object.freeze({ neutral: false, status: response.status || 204 });
    }

    const status = response ? response.status : 0;
    const backendCode = await extractSafeBackendErrorCode(response);
    if (action === 'send' && isNeutralSendCodeStatus(status, backendCode)) {
      return Object.freeze({ neutral: true, status, backendCode });
    }
    throw new PublicForgotPasswordHttpError(status, action, backendCode);
  } catch (error) {
    if (
      error instanceof PublicForgotPasswordValidationError ||
      error instanceof PublicForgotPasswordHttpError ||
      error instanceof PublicForgotPasswordTimeoutError ||
      (error && error.name === 'PublicLoginConfigError')
    ) {
      throw error;
    }
    if (error && error.name === 'AbortError') {
      throw new PublicForgotPasswordTimeoutError();
    }
    throw new PublicForgotPasswordNetworkError();
  } finally {
    clearTimeout(timeoutId);
  }
}

export async function performForgotPasswordSendCode({
  apiBaseUrl,
  email,
  fetchImpl = globalThis.fetch,
  timeoutMs = FORGOT_PASSWORD_TIMEOUT_MS,
  AbortControllerClass = globalThis.AbortController,
} = {}) {
  const request = buildSendCodeRequest({ apiBaseUrl, email });
  return performForgotPasswordRequest({
    request,
    action: 'send',
    fetchImpl,
    timeoutMs,
    AbortControllerClass,
  });
}

export async function performForgotPasswordValidateCode({
  apiBaseUrl,
  email,
  codigo,
  fetchImpl = globalThis.fetch,
  timeoutMs = FORGOT_PASSWORD_TIMEOUT_MS,
  AbortControllerClass = globalThis.AbortController,
} = {}) {
  const request = buildValidateCodeRequest({ apiBaseUrl, email, codigo });
  return performForgotPasswordRequest({
    request,
    action: 'validate',
    fetchImpl,
    timeoutMs,
    AbortControllerClass,
  });
}

export async function performForgotPasswordReset({
  apiBaseUrl,
  email,
  codigo,
  novaSenha,
  confirmarSenha,
  fetchImpl = globalThis.fetch,
  timeoutMs = FORGOT_PASSWORD_TIMEOUT_MS,
  AbortControllerClass = globalThis.AbortController,
} = {}) {
  const request = buildResetPasswordRequest({
    apiBaseUrl,
    email,
    codigo,
    novaSenha,
    confirmarSenha,
  });
  return performForgotPasswordRequest({
    request,
    action: 'reset',
    fetchImpl,
    timeoutMs,
    AbortControllerClass,
  });
}
