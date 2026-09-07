import {
  applyPublicLanguage,
  cleanupLegacyFlutterWorker,
  selectPublicLanguage,
  setupPublicLanguageSwitcher,
} from './public-locale.mjs';
import {
  REGISTER_DICTIONARY,
  REGISTER_SUCCESS_LOGIN_PATH,
  REGISTER_TIMEOUT_MS,
  PublicRegisterValidationError,
  performPublicRegister,
  registerErrorKeyFromError,
  resolvePublicApiConfig,
  validateRegisterFields,
} from './register-core.mjs';
import {
  googleErrorKey,
  performGoogleLink,
  performGoogleRegistration,
  renderGoogleButton,
  resolveGoogleWebClientId,
} from './google-auth-core.mjs';

(function () {
  'use strict';

  const GOOGLE_COPY = Object.freeze({
    pt: Object.freeze({
      'google.form.subtitle': 'Crie com Google sem senha do SixoApp ou escolha um login e senha tradicionais.',
      'google.traditional.subtitle': 'Use esta opção somente se preferir criar um login e uma senha do SixoApp.',
      'google.helper.enabled': 'Crie sua conta diretamente com o Google. Nenhuma senha do SixoApp será criada.',
      'google.helper.disabled': 'Aceite os termos acima para criar sua conta com Google.',
      'google.divider': 'ou crie com login e senha',
      'google.terms.prefix': 'Concordo com os ',
      'google.terms.link': 'Termos de Serviço',
      'google.privacy.prefix': ' e a ',
      'google.privacy.link': 'Política de Privacidade',
      'google.link.title': 'Este e-mail já possui um acesso SixoApp',
      'google.link.body': 'Informe sua senha atual somente para vincular esta Conta Google ao acesso existente. Sua senha não será alterada.',
      'google.link.password': 'Senha atual',
      'google.link.submit': 'Vincular e criar minha empresa',
      'google.link.cancel': 'Cancelar',
      'google.link.required': 'Já existe uma conta com este e-mail. Confirme sua senha atual para vincular o Google com segurança.',
      'google.link.passwordRequired': 'Informe sua senha atual para concluir o vínculo.',
      'google.error.termsRequired': 'Aceite os Termos de Serviço e a Política de Privacidade para continuar.',
      'google.error.config': 'O cadastro com Google não está configurado corretamente.',
      'google.error.timeout': 'O cadastro com Google demorou mais do que o esperado. Tente novamente.',
      'google.error.network': 'Não foi possível conectar ao serviço de autenticação Google.',
      'google.error.invalidCredential': 'Não foi possível validar sua Conta Google ou a senha atual informada.',
      'google.error.unavailable': 'O cadastro com Google está temporariamente indisponível.',
      'google.error.unexpected': 'Não foi possível criar a conta com Google agora. Tente novamente.',
      'google.error.notFound': 'Não foi possível localizar a conta existente.',
      'google.error.registrationRequired': 'Não foi possível localizar o cadastro.',
    }),
    en: Object.freeze({
      'google.form.subtitle': 'Create with Google without a SixoApp password, or choose a traditional login and password.',
      'google.traditional.subtitle': 'Use this option only if you prefer to create a SixoApp login and password.',
      'google.helper.enabled': 'Create your account directly with Google. No SixoApp password will be created.',
      'google.helper.disabled': 'Accept the terms above to create your account with Google.',
      'google.divider': 'or create a login and password',
      'google.terms.prefix': 'I agree to the ',
      'google.terms.link': 'Terms of Service',
      'google.privacy.prefix': ' and the ',
      'google.privacy.link': 'Privacy Policy',
      'google.link.title': 'This email already has SixoApp access',
      'google.link.body': 'Enter your current password only to link this Google Account to your existing access. Your password will not be changed.',
      'google.link.password': 'Current password',
      'google.link.submit': 'Link and create my company',
      'google.link.cancel': 'Cancel',
      'google.link.required': 'An account already exists with this email. Confirm your current password to link Google securely.',
      'google.link.passwordRequired': 'Enter your current password to finish linking.',
      'google.error.termsRequired': 'Accept the Terms of Service and Privacy Policy to continue.',
      'google.error.config': 'Google signup is not configured correctly.',
      'google.error.timeout': 'Google signup took longer than expected. Try again.',
      'google.error.network': 'Could not connect to the Google authentication service.',
      'google.error.invalidCredential': 'We could not validate your Google Account or current password.',
      'google.error.unavailable': 'Google signup is temporarily unavailable.',
      'google.error.unexpected': 'Could not create your account with Google right now. Try again.',
      'google.error.notFound': 'Could not find the existing account.',
      'google.error.registrationRequired': 'Could not find the registration.',
    }),
    es: Object.freeze({
      'google.form.subtitle': 'Crea con Google sin contraseña de SixoApp o elige un login y contraseña tradicionales.',
      'google.traditional.subtitle': 'Usa esta opción solo si prefieres crear un login y una contraseña de SixoApp.',
      'google.helper.enabled': 'Crea tu cuenta directamente con Google. No se creará una contraseña de SixoApp.',
      'google.helper.disabled': 'Acepta los términos para crear tu cuenta con Google.',
      'google.divider': 'o crea un login y contraseña',
      'google.terms.prefix': 'Acepto los ',
      'google.terms.link': 'Términos de Servicio',
      'google.privacy.prefix': ' y la ',
      'google.privacy.link': 'Política de Privacidad',
      'google.link.title': 'Este e-mail ya tiene acceso a SixoApp',
      'google.link.body': 'Informa tu contraseña actual solo para vincular esta Cuenta de Google al acceso existente. Tu contraseña no será modificada.',
      'google.link.password': 'Contraseña actual',
      'google.link.submit': 'Vincular y crear mi empresa',
      'google.link.cancel': 'Cancelar',
      'google.link.required': 'Ya existe una cuenta con este e-mail. Confirma tu contraseña actual para vincular Google de forma segura.',
      'google.link.passwordRequired': 'Informa tu contraseña actual para concluir la vinculación.',
      'google.error.termsRequired': 'Acepta los Términos de Servicio y la Política de Privacidad para continuar.',
      'google.error.config': 'El registro con Google no está configurado correctamente.',
      'google.error.timeout': 'El registro con Google tardó más de lo esperado. Intenta nuevamente.',
      'google.error.network': 'No fue posible conectar con el servicio de autenticación de Google.',
      'google.error.invalidCredential': 'No fue posible validar tu Cuenta de Google o la contraseña actual.',
      'google.error.unavailable': 'El registro con Google no está disponible temporalmente.',
      'google.error.unexpected': 'No fue posible crear la cuenta con Google ahora. Intenta nuevamente.',
      'google.error.notFound': 'No fue posible localizar la cuenta existente.',
      'google.error.registrationRequired': 'No fue posible localizar el registro.',
    }),
  });

  const state = {
    apiConfig: null,
    googleClientId: null,
    language: 'pt',
    passwordVisible: false,
    confirmPasswordVisible: false,
    submitting: false,
    googleBusy: false,
    pendingGoogleAccessToken: null,
    feedbackKey: null,
    completed: false,
  };

  function copy(key) {
    return GOOGLE_COPY[state.language]?.[key] ||
      GOOGLE_COPY.pt[key] ||
      REGISTER_DICTIONARY[state.language]?.[key] ||
      REGISTER_DICTIONARY.pt[key] ||
      key;
  }

  function setFeedback(elements, key, focus = false) {
    state.feedbackKey = key;
    elements.feedback.hidden = false;
    elements.feedback.textContent = copy(key);
    if (focus) elements.feedback.focus({ preventScroll: false });
  }

  function clearFeedback(elements) {
    state.feedbackKey = null;
    elements.feedback.hidden = true;
    elements.feedback.textContent = '';
  }

  function updateCopy(elements) {
    elements.formSubtitle.textContent = copy('google.form.subtitle');
    elements.traditionalSubtitle.textContent = copy('google.traditional.subtitle');
    elements.googleDivider.textContent = copy('google.divider');
    elements.googleTermsPrefix.textContent = copy('google.terms.prefix');
    elements.googleTermsLink.textContent = copy('google.terms.link');
    elements.googlePrivacyPrefix.textContent = copy('google.privacy.prefix');
    elements.googlePrivacyLink.textContent = copy('google.privacy.link');
    elements.googleLinkTitle.textContent = copy('google.link.title');
    elements.googleLinkBody.textContent = copy('google.link.body');
    elements.googleLinkPasswordLabel.textContent = copy('google.link.password');
    elements.googleLinkSubmit.textContent = copy('google.link.submit');
    elements.googleLinkCancel.textContent = copy('google.link.cancel');
    updateGoogleAvailability(elements);
  }

  function updatePasswordToggle(elements, confirm = false) {
    const visible = confirm ? state.confirmPasswordVisible : state.passwordVisible;
    const input = confirm ? elements.confirmPassword : elements.password;
    const toggle = confirm ? elements.confirmPasswordToggle : elements.passwordToggle;
    const label = confirm ? elements.confirmPasswordToggleLabel : elements.passwordToggleLabel;
    const textKey = visible ? 'form.password.hide' : 'form.password.show';
    const ariaKey = confirm
      ? (visible ? 'form.confirmPassword.hideAria' : 'form.confirmPassword.showAria')
      : (visible ? 'form.password.hideAria' : 'form.password.showAria');
    input.type = visible ? 'text' : 'password';
    toggle.setAttribute('aria-pressed', visible ? 'true' : 'false');
    toggle.setAttribute('aria-label', copy(ariaKey));
    label.textContent = copy(textKey);
  }

  function updateMismatch(elements) {
    const mismatched = elements.confirmPassword.value.length > 0 &&
      elements.password.value !== elements.confirmPassword.value;
    elements.passwordMatchFeedback.hidden = !mismatched;
    elements.passwordMatchFeedback.textContent = mismatched
      ? copy('error.passwordMismatch')
      : '';
  }

  function updateGoogleAvailability(elements) {
    const enabled = Boolean(
      state.googleClientId &&
      elements.terms.checked &&
      !state.submitting &&
      !state.googleBusy &&
      !state.completed,
    );
    elements.googleButtonShell.classList.toggle('is-disabled', !enabled);
    const button = elements.googleButtonShell.querySelector('button');
    if (button) button.disabled = !enabled;
    elements.googleHelper.textContent = copy(
      enabled ? 'google.helper.enabled' : 'google.helper.disabled',
    );
    elements.googleLinkSubmit.disabled = state.googleBusy;
    elements.googleLinkCancel.disabled = state.googleBusy;
    elements.googleLinkPassword.disabled = state.googleBusy;
  }

  function setLoading(elements, loading) {
    state.submitting = loading;
    elements.form.setAttribute('aria-busy', loading ? 'true' : 'false');
    const disabled = loading || state.apiConfig === null || state.completed;
    elements.submit.disabled = disabled;
    elements.login.disabled = disabled;
    elements.password.disabled = disabled;
    elements.confirmPassword.disabled = disabled;
    elements.terms.disabled = disabled;
    elements.passwordToggle.disabled = disabled;
    elements.confirmPasswordToggle.disabled = disabled;
    elements.submit.classList.toggle('is-loading', loading);
    elements.submitLabel.textContent = copy(loading ? 'form.loading' : 'form.submit');
    updateGoogleAvailability(elements);
  }

  function setGoogleBusy(elements, busy) {
    state.googleBusy = busy;
    updateGoogleAvailability(elements);
  }

  function focusValidationTarget(elements, error) {
    if (!(error instanceof PublicRegisterValidationError)) return;
    if (error.code === 'terms') return elements.terms.focus();
    if (error.code === 'passwordTooShort') return elements.password.focus();
    if (error.code === 'passwordMismatch') return elements.confirmPassword.focus();
    if (!elements.login.value.trim()) return elements.login.focus();
    if (!elements.password.value) return elements.password.focus();
    elements.confirmPassword.focus();
  }

  function validateTraditional(elements) {
    try {
      return validateRegisterFields({
        login: elements.login.value,
        senha: elements.password.value,
        confirmarSenha: elements.confirmPassword.value,
        aceitaTermos: elements.terms.checked,
      });
    } catch (error) {
      updateMismatch(elements);
      setFeedback(elements, registerErrorKeyFromError(error), false);
      focusValidationTarget(elements, error);
      return null;
    }
  }

  async function handleSubmit(elements, event) {
    event.preventDefault();
    if (state.submitting || state.googleBusy) {
      setFeedback(elements, 'error.pending', true);
      return;
    }
    clearFeedback(elements);
    if (state.apiConfig === null) {
      setFeedback(elements, 'error.config', true);
      return;
    }
    const values = validateTraditional(elements);
    if (!values) return;

    setLoading(elements, true);
    try {
      await performPublicRegister({
        apiBaseUrl: state.apiConfig.apiBaseUrl,
        login: values.login,
        senha: values.senha,
        confirmarSenha: elements.confirmPassword.value,
        aceitaTermos: elements.terms.checked,
        timeoutMs: REGISTER_TIMEOUT_MS,
      });
      state.completed = true;
      elements.password.value = '';
      elements.confirmPassword.value = '';
      elements.formCard.hidden = true;
      elements.successCard.hidden = false;
      elements.successTitle.focus({ preventScroll: false });
    } catch (error) {
      setLoading(elements, false);
      setFeedback(elements, registerErrorKeyFromError(error), true);
    }
  }

  function hideGoogleLink(elements) {
    state.pendingGoogleAccessToken = null;
    elements.googleLinkPassword.value = '';
    elements.googleLinkPanel.hidden = true;
  }

  function showGoogleLink(elements, accessToken) {
    state.pendingGoogleAccessToken = accessToken;
    elements.googleLinkPanel.hidden = false;
    setFeedback(elements, 'google.link.required', false);
    elements.googleLinkPassword.focus();
  }

  async function handleGoogleCredential(elements, response) {
    if (state.googleBusy || state.submitting || state.completed) return;
    if (!elements.terms.checked) {
      setFeedback(elements, 'google.error.termsRequired', true);
      elements.terms.focus();
      return;
    }
    if (response?.error) {
      setFeedback(elements, 'google.error.invalidCredential', true);
      return;
    }

    const accessToken = String(response?.access_token || '').trim();
    if (!accessToken) {
      setFeedback(elements, 'google.error.invalidCredential', true);
      return;
    }

    clearFeedback(elements);
    hideGoogleLink(elements);
    setGoogleBusy(elements, true);
    try {
      await performGoogleRegistration({
        apiBaseUrl: state.apiConfig.apiBaseUrl,
        accessToken,
        aceiteTermos: true,
        idioma: state.language,
      });
      window.location.replace('/app');
    } catch (error) {
      setGoogleBusy(elements, false);
      const key = googleErrorKey(error, 'register');
      if (key === 'google.link.required') {
        showGoogleLink(elements, accessToken);
        return;
      }
      setFeedback(elements, key, true);
    }
  }

  async function handleGoogleLink(elements) {
    if (!state.pendingGoogleAccessToken || state.googleBusy) return;
    if (!elements.terms.checked) {
      setFeedback(elements, 'google.error.termsRequired', true);
      elements.terms.focus();
      return;
    }
    const senha = elements.googleLinkPassword.value;
    if (!senha) {
      setFeedback(elements, 'google.link.passwordRequired', true);
      elements.googleLinkPassword.focus();
      return;
    }

    clearFeedback(elements);
    setGoogleBusy(elements, true);
    try {
      await performGoogleLink({
        apiBaseUrl: state.apiConfig.apiBaseUrl,
        accessToken: state.pendingGoogleAccessToken,
        senha,
        fluxo: 'CADASTRO',
        aceiteTermos: true,
        idioma: state.language,
      });
      window.location.replace('/app');
    } catch (error) {
      setGoogleBusy(elements, false);
      setFeedback(elements, googleErrorKey(error, 'register'), true);
    }
  }

  async function renderGoogle(elements) {
    if (!state.googleClientId) return;
    try {
      await renderGoogleButton({
        container: elements.googleButtonShell,
        clientId: state.googleClientId,
        language: state.language,
        text: 'signup_with',
        callback: (response) => handleGoogleCredential(elements, response),
      });
    } catch (_) {
      setFeedback(elements, 'google.error.config', false);
    }
    updateGoogleAvailability(elements);
  }

  function collectElements() {
    return {
      formCard: document.querySelector('[data-register-form-card]'),
      formSubtitle: document.querySelector('.register-card-header p'),
      traditionalSubtitle: document.querySelector('.auth-method-summary-copy small'),
      successCard: document.querySelector('[data-register-success-card]'),
      successTitle: document.querySelector('[data-register-success-title]'),
      successLogin: document.querySelector('[data-register-success-login]'),
      form: document.querySelector('[data-register-form]'),
      login: document.querySelector('[data-register-login]'),
      password: document.querySelector('[data-register-password]'),
      confirmPassword: document.querySelector('[data-register-confirm-password]'),
      terms: document.querySelector('[data-register-terms]'),
      passwordToggle: document.querySelector('[data-register-password-toggle]'),
      passwordToggleLabel: document.querySelector('[data-register-password-toggle-label]'),
      confirmPasswordToggle: document.querySelector('[data-register-confirm-password-toggle]'),
      confirmPasswordToggleLabel: document.querySelector('[data-register-confirm-password-toggle-label]'),
      passwordMatchFeedback: document.querySelector('[data-register-password-match-feedback]'),
      submit: document.querySelector('[data-register-submit]'),
      submitLabel: document.querySelector('[data-register-submit-label]'),
      feedback: document.querySelector('[data-register-feedback]'),
      googleButtonShell: document.querySelector('[data-google-register-button]'),
      googleHelper: document.querySelector('[data-google-helper]'),
      googleDivider: document.querySelector('[data-google-divider]'),
      googleTermsPrefix: document.querySelector('[data-google-terms-prefix]'),
      googleTermsLink: document.querySelector('[data-google-terms-link]'),
      googlePrivacyPrefix: document.querySelector('[data-google-privacy-prefix]'),
      googlePrivacyLink: document.querySelector('[data-google-privacy-link]'),
      googleLinkPanel: document.querySelector('[data-google-link-panel]'),
      googleLinkTitle: document.querySelector('[data-google-link-title]'),
      googleLinkBody: document.querySelector('[data-google-link-body]'),
      googleLinkPasswordLabel: document.querySelector('[data-google-link-password-label]'),
      googleLinkPassword: document.querySelector('[data-google-link-password]'),
      googleLinkSubmit: document.querySelector('[data-google-link-submit]'),
      googleLinkCancel: document.querySelector('[data-google-link-cancel]'),
    };
  }

  function initialize() {
    const elements = collectElements();
    if (!Object.values(elements).every(Boolean)) return;

    document.documentElement.classList.add('has-js');
    state.language = applyPublicLanguage({
      dictionary: REGISTER_DICTIONARY,
      language: selectPublicLanguage(),
    });
    updateCopy(elements);

    setupPublicLanguageSwitcher({
      dictionary: REGISTER_DICTIONARY,
      onChange: (language) => {
        state.language = language;
        updatePasswordToggle(elements, false);
        updatePasswordToggle(elements, true);
        updateMismatch(elements);
        updateCopy(elements);
        if (state.feedbackKey) elements.feedback.textContent = copy(state.feedbackKey);
        void renderGoogle(elements);
      },
    });

    updatePasswordToggle(elements, false);
    updatePasswordToggle(elements, true);
    elements.passwordToggle.addEventListener('click', () => {
      state.passwordVisible = !state.passwordVisible;
      updatePasswordToggle(elements, false);
      elements.password.focus();
    });
    elements.confirmPasswordToggle.addEventListener('click', () => {
      state.confirmPasswordVisible = !state.confirmPasswordVisible;
      updatePasswordToggle(elements, true);
      elements.confirmPassword.focus();
    });
    elements.password.addEventListener('input', () => updateMismatch(elements));
    elements.confirmPassword.addEventListener('input', () => updateMismatch(elements));
    elements.terms.addEventListener('change', () => updateGoogleAvailability(elements));
    elements.successLogin.addEventListener('click', () => {
      window.location.replace(REGISTER_SUCCESS_LOGIN_PATH);
    });
    elements.googleLinkSubmit.addEventListener('click', () => void handleGoogleLink(elements));
    elements.googleLinkCancel.addEventListener('click', () => {
      hideGoogleLink(elements);
      clearFeedback(elements);
    });
    elements.googleLinkPassword.addEventListener('keydown', (event) => {
      if (event.key === 'Enter') {
        event.preventDefault();
        void handleGoogleLink(elements);
      }
    });

    try {
      state.apiConfig = resolvePublicApiConfig(window.SIXAPP_PUBLIC_CONFIG);
      state.googleClientId = resolveGoogleWebClientId(window.SIXAPP_PUBLIC_CONFIG);
    } catch (_) {
      state.apiConfig = null;
      setFeedback(elements, 'error.config', false);
    }

    setLoading(elements, false);
    elements.form.addEventListener('submit', (event) => handleSubmit(elements, event));
    void renderGoogle(elements);
    cleanupLegacyFlutterWorker();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initialize);
  } else {
    initialize();
  }
})();
