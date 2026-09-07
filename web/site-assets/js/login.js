import {
  applyPublicLanguage,
  cleanupLegacyFlutterWorker,
  selectPublicLanguage,
  setupPublicLanguageSwitcher,
} from './public-locale.mjs';
import {
  LOGIN_DICTIONARY,
  LOGIN_TIMEOUT_MS,
  loginErrorKeyFromError,
  performPublicLogin,
  resolvePublicApiConfig,
  resolvePublicLoginRedirect,
  shouldBlockPublicLoginOnMobile,
} from './login-core.mjs';
import {
  googleErrorKey,
  performGoogleLink,
  performGoogleLogin,
  renderGoogleButton,
  resolveGoogleWebClientId,
} from './google-auth-core.mjs';

(function () {
  'use strict';

  const GOOGLE_COPY = Object.freeze({
    pt: Object.freeze({
      'google.form.subtitle': 'Entre com sua Conta Google ou use seu login e senha do SixoApp.',
      'google.helper': 'Use sua Conta Google para entrar com segurança.',
      'google.divider': 'ou use seu login e senha',
      'google.register.copy': 'Esta Conta Google ainda não tem cadastro.',
      'google.register.link': 'Criar conta com Google',
      'google.link.title': 'Vincule sua Conta Google ao acesso existente',
      'google.link.body': 'Por segurança, informe uma vez a senha atual do SixoApp. Sua senha não será alterada.',
      'google.link.password': 'Senha atual',
      'google.link.submit': 'Vincular e entrar',
      'google.link.cancel': 'Cancelar',
      'google.link.required': 'Encontramos uma conta com este e-mail. Confirme sua senha atual para vincular o Google com segurança.',
      'google.link.passwordRequired': 'Informe sua senha atual para concluir o vínculo.',
      'google.error.registrationRequired': 'Esta Conta Google ainda não possui uma conta SixoApp.',
      'google.error.config': 'O login com Google não está configurado corretamente.',
      'google.error.timeout': 'O login com Google demorou mais do que o esperado. Tente novamente.',
      'google.error.network': 'Não foi possível conectar ao serviço de autenticação Google.',
      'google.error.invalidCredential': 'Não foi possível validar sua Conta Google ou a senha atual informada.',
      'google.error.unavailable': 'O login com Google está temporariamente indisponível.',
      'google.error.unexpected': 'Não foi possível entrar com Google agora. Tente novamente.',
      'google.error.termsRequired': 'É necessário aceitar os termos para continuar.',
      'google.error.notFound': 'Não foi possível localizar a conta.',
    }),
    en: Object.freeze({
      'google.form.subtitle': 'Sign in with your Google Account or use your SixoApp login and password.',
      'google.helper': 'Use your Google Account to sign in securely.',
      'google.divider': 'or use your login and password',
      'google.register.copy': 'This Google Account does not have a SixoApp account yet.',
      'google.register.link': 'Create account with Google',
      'google.link.title': 'Link your Google Account to your existing access',
      'google.link.body': 'For security, enter your current SixoApp password once. Your password will not be changed.',
      'google.link.password': 'Current password',
      'google.link.submit': 'Link and sign in',
      'google.link.cancel': 'Cancel',
      'google.link.required': 'We found an account with this email. Confirm your current password to link Google securely.',
      'google.link.passwordRequired': 'Enter your current password to finish linking.',
      'google.error.registrationRequired': 'This Google Account does not have a SixoApp account yet.',
      'google.error.config': 'Google sign-in is not configured correctly.',
      'google.error.timeout': 'Google sign-in took longer than expected. Try again.',
      'google.error.network': 'Could not connect to the Google authentication service.',
      'google.error.invalidCredential': 'We could not validate your Google Account or current password.',
      'google.error.unavailable': 'Google sign-in is temporarily unavailable.',
      'google.error.unexpected': 'Could not sign in with Google right now. Try again.',
      'google.error.termsRequired': 'You must accept the terms to continue.',
      'google.error.notFound': 'Could not find the account.',
    }),
    es: Object.freeze({
      'google.form.subtitle': 'Entra con tu Cuenta de Google o usa tu login y contraseña de SixoApp.',
      'google.helper': 'Usa tu Cuenta de Google para entrar de forma segura.',
      'google.divider': 'o usa tu login y contraseña',
      'google.register.copy': 'Esta Cuenta de Google aún no tiene una cuenta SixoApp.',
      'google.register.link': 'Crear cuenta con Google',
      'google.link.title': 'Vincula tu Cuenta de Google al acceso existente',
      'google.link.body': 'Por seguridad, informa una vez tu contraseña actual de SixoApp. Tu contraseña no será modificada.',
      'google.link.password': 'Contraseña actual',
      'google.link.submit': 'Vincular y entrar',
      'google.link.cancel': 'Cancelar',
      'google.link.required': 'Encontramos una cuenta con este e-mail. Confirma tu contraseña actual para vincular Google de forma segura.',
      'google.link.passwordRequired': 'Informa tu contraseña actual para concluir la vinculación.',
      'google.error.registrationRequired': 'Esta Cuenta de Google aún no posee una cuenta SixoApp.',
      'google.error.config': 'El acceso con Google no está configurado correctamente.',
      'google.error.timeout': 'El acceso con Google tardó más de lo esperado. Intenta nuevamente.',
      'google.error.network': 'No fue posible conectar con el servicio de autenticación de Google.',
      'google.error.invalidCredential': 'No fue posible validar tu Cuenta de Google o la contraseña actual.',
      'google.error.unavailable': 'El acceso con Google no está disponible temporalmente.',
      'google.error.unexpected': 'No fue posible entrar con Google ahora. Intenta nuevamente.',
      'google.error.termsRequired': 'Es necesario aceptar los términos para continuar.',
      'google.error.notFound': 'No fue posible localizar la cuenta.',
    }),
  });

  const state = {
    apiConfig: null,
    googleClientId: null,
    language: 'pt',
    mobileBlocked: false,
    passwordVisible: false,
    submitting: false,
    googleBusy: false,
    pendingGoogleAccessToken: null,
  };

  function copy(key) {
    return GOOGLE_COPY[state.language]?.[key] ||
      GOOGLE_COPY.pt[key] ||
      LOGIN_DICTIONARY[state.language]?.[key] ||
      LOGIN_DICTIONARY.pt[key] ||
      key;
  }

  function destination() {
    return resolvePublicLoginRedirect(window.location.search, window.location.origin);
  }

  function setFeedback(elements, key, focus = false) {
    elements.feedback.hidden = false;
    elements.feedback.textContent = copy(key);
    if (focus) elements.feedback.focus({ preventScroll: false });
  }

  function clearFeedback(elements) {
    elements.feedback.hidden = true;
    elements.feedback.textContent = '';
  }

  function updateGoogleCopy(elements) {
    elements.formSubtitle.textContent = copy('google.form.subtitle');
    elements.googleHelper.textContent = copy('google.helper');
    elements.googleDivider.textContent = copy('google.divider');
    elements.googleRegisterCopy.textContent = copy('google.register.copy');
    elements.googleRegisterLink.textContent = copy('google.register.link');
    elements.googleLinkTitle.textContent = copy('google.link.title');
    elements.googleLinkBody.textContent = copy('google.link.body');
    elements.googleLinkPasswordLabel.textContent = copy('google.link.password');
    elements.googleLinkSubmit.textContent = copy('google.link.submit');
    elements.googleLinkCancel.textContent = copy('google.link.cancel');
  }

  function updatePasswordToggle(elements) {
    const labelKey = state.passwordVisible ? 'form.password.hide' : 'form.password.show';
    const ariaKey = state.passwordVisible ? 'form.password.hideAria' : 'form.password.showAria';
    elements.password.type = state.passwordVisible ? 'text' : 'password';
    elements.passwordToggle.setAttribute('aria-pressed', state.passwordVisible ? 'true' : 'false');
    elements.passwordToggle.setAttribute('aria-label', copy(ariaKey));
    elements.passwordToggleLabel.textContent = copy(labelKey);
  }

  function updateGoogleAvailability(elements) {
    const disabled = state.mobileBlocked || state.submitting || state.googleBusy || !state.googleClientId;
    elements.googleButtonShell.classList.toggle('is-disabled', disabled);
    const button = elements.googleButtonShell.querySelector('button');
    if (button) button.disabled = disabled;
    elements.googleLinkSubmit.disabled = state.googleBusy;
    elements.googleLinkCancel.disabled = state.googleBusy;
    elements.googleLinkPassword.disabled = state.googleBusy;
  }

  function applyMobileBlockState(elements) {
    elements.mobileBlock.hidden = !state.mobileBlocked;
    elements.card.classList.toggle('is-mobile-blocked', state.mobileBlocked);
    elements.form.setAttribute('aria-disabled', state.mobileBlocked ? 'true' : 'false');
    updateGoogleAvailability(elements);
  }

  function setLoading(elements, isLoading) {
    state.submitting = isLoading;
    elements.form.setAttribute('aria-busy', isLoading ? 'true' : 'false');
    const disabled = isLoading || state.apiConfig === null || state.mobileBlocked;
    elements.submit.disabled = disabled;
    elements.login.disabled = disabled;
    elements.password.disabled = disabled;
    elements.passwordToggle.disabled = disabled;
    elements.submit.classList.toggle('is-loading', isLoading);
    elements.submitLabel.textContent = copy(isLoading ? 'form.loading' : 'form.submit');
    updateGoogleAvailability(elements);
  }

  function setGoogleBusy(elements, busy) {
    state.googleBusy = busy;
    updateGoogleAvailability(elements);
  }

  function disableForConfigError(elements) {
    state.apiConfig = null;
    setLoading(elements, false);
    setFeedback(elements, 'error.config', false);
  }

  function validateForm(elements) {
    const login = elements.login.value.trim();
    const senha = elements.password.value;
    if (!login) {
      setFeedback(elements, 'error.requiredLogin', false);
      elements.login.focus();
      return null;
    }
    if (!senha) {
      setFeedback(elements, 'error.requiredPassword', false);
      elements.password.focus();
      return null;
    }
    return { login, senha };
  }

  async function handleSubmit(elements, event) {
    event.preventDefault();
    if (state.mobileBlocked) {
      setFeedback(elements, 'error.mobileBlocked', true);
      return;
    }
    if (state.submitting || state.googleBusy) {
      setFeedback(elements, 'error.pending', true);
      return;
    }
    clearFeedback(elements);
    if (state.apiConfig === null) {
      disableForConfigError(elements);
      return;
    }
    const values = validateForm(elements);
    if (!values) return;

    setLoading(elements, true);
    try {
      await performPublicLogin({
        apiBaseUrl: state.apiConfig.apiBaseUrl,
        login: values.login,
        senha: values.senha,
        timeoutMs: LOGIN_TIMEOUT_MS,
      });
      elements.password.value = '';
      window.location.replace(destination());
    } catch (error) {
      setLoading(elements, false);
      setFeedback(elements, loginErrorKeyFromError(error), true);
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
    if (state.mobileBlocked || state.googleBusy || state.submitting) return;
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
    elements.googleRegisterHint.hidden = true;
    hideGoogleLink(elements);
    setGoogleBusy(elements, true);
    try {
      await performGoogleLogin({
        apiBaseUrl: state.apiConfig.apiBaseUrl,
        accessToken,
        idioma: state.language,
      });
      window.location.replace(destination());
    } catch (error) {
      setGoogleBusy(elements, false);
      const key = googleErrorKey(error, 'login');
      if (key === 'google.link.required') {
        showGoogleLink(elements, accessToken);
        return;
      }
      if (key === 'google.error.registrationRequired') {
        elements.googleRegisterHint.hidden = false;
      }
      setFeedback(elements, key, true);
    }
  }

  async function handleGoogleLink(elements) {
    if (!state.pendingGoogleAccessToken || state.googleBusy) return;
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
        fluxo: 'LOGIN',
        aceiteTermos: false,
        idioma: state.language,
      });
      elements.googleLinkPassword.value = '';
      window.location.replace(destination());
    } catch (error) {
      setGoogleBusy(elements, false);
      setFeedback(elements, googleErrorKey(error, 'login'), true);
    }
  }

  async function renderGoogle(elements) {
    if (!state.googleClientId || state.mobileBlocked) return;
    try {
      await renderGoogleButton({
        container: elements.googleButtonShell,
        clientId: state.googleClientId,
        language: state.language,
        text: 'signin_with',
        callback: (response) => handleGoogleCredential(elements, response),
      });
    } catch (_) {
      setFeedback(elements, 'google.error.config', false);
    }
    updateGoogleAvailability(elements);
  }

  function collectElements() {
    return {
      card: document.querySelector('[data-login-card]'),
      formSubtitle: document.querySelector('.login-card-header p'),
      form: document.querySelector('[data-login-form]'),
      login: document.querySelector('[data-login-input]'),
      mobileBlock: document.querySelector('[data-login-mobile-block]'),
      password: document.querySelector('[data-password-input]'),
      passwordToggle: document.querySelector('[data-password-toggle]'),
      passwordToggleLabel: document.querySelector('[data-password-toggle-label]'),
      submit: document.querySelector('[data-login-submit]'),
      submitLabel: document.querySelector('[data-login-submit-label]'),
      feedback: document.querySelector('[data-login-feedback]'),
      googleButtonShell: document.querySelector('[data-google-login-button]'),
      googleHelper: document.querySelector('[data-google-helper]'),
      googleDivider: document.querySelector('[data-google-divider]'),
      googleRegisterHint: document.querySelector('[data-google-register-hint]'),
      googleRegisterCopy: document.querySelector('[data-google-register-copy]'),
      googleRegisterLink: document.querySelector('[data-google-register-link]'),
      googleLinkPanel: document.querySelector('[data-google-link-panel]'),
      googleLinkTitle: document.querySelector('[data-google-link-title]'),
      googleLinkBody: document.querySelector('[data-google-link-body]'),
      googleLinkPasswordLabel: document.querySelector('[data-google-link-password-label]'),
      googleLinkPassword: document.querySelector('[data-google-link-password]'),
      googleLinkSubmit: document.querySelector('[data-google-link-submit]'),
      googleLinkCancel: document.querySelector('[data-google-link-cancel]'),
    };
  }

  function hasRequiredElements(elements) {
    return Object.values(elements).every(Boolean);
  }

  function initialize() {
    const elements = collectElements();
    if (!hasRequiredElements(elements)) return;

    document.documentElement.classList.add('has-js');
    state.language = applyPublicLanguage({
      dictionary: LOGIN_DICTIONARY,
      language: selectPublicLanguage(),
    });
    updateGoogleCopy(elements);

    setupPublicLanguageSwitcher({
      dictionary: LOGIN_DICTIONARY,
      onChange: (language) => {
        state.language = language;
        updatePasswordToggle(elements);
        updateGoogleCopy(elements);
        applyMobileBlockState(elements);
        setLoading(elements, state.submitting);
        void renderGoogle(elements);
      },
    });

    state.mobileBlocked = shouldBlockPublicLoginOnMobile(window);
    updatePasswordToggle(elements);
    applyMobileBlockState(elements);

    elements.passwordToggle.addEventListener('click', () => {
      state.passwordVisible = !state.passwordVisible;
      updatePasswordToggle(elements);
      elements.password.focus();
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

    if (!state.mobileBlocked) {
      try {
        state.apiConfig = resolvePublicApiConfig(window.SIXAPP_PUBLIC_CONFIG);
        state.googleClientId = resolveGoogleWebClientId(window.SIXAPP_PUBLIC_CONFIG);
      } catch (_) {
        disableForConfigError(elements);
      }
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
