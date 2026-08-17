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

(function () {
  'use strict';

  const state = {
    apiConfig: null,
    language: 'pt',
    mobileBlocked: false,
    passwordVisible: false,
    submitting: false,
  };

  function copy(key) {
    return LOGIN_DICTIONARY[state.language]?.[key] ||
      LOGIN_DICTIONARY.pt[key] ||
      key;
  }

  function setFeedback(elements, key, focus = false) {
    elements.feedback.hidden = false;
    elements.feedback.textContent = copy(key);
    if (focus) {
      elements.feedback.focus({ preventScroll: false });
    }
  }

  function clearFeedback(elements) {
    elements.feedback.hidden = true;
    elements.feedback.textContent = '';
  }

  function updatePasswordToggle(elements) {
    const labelKey = state.passwordVisible
      ? 'form.password.hide'
      : 'form.password.show';
    const ariaKey = state.passwordVisible
      ? 'form.password.hideAria'
      : 'form.password.showAria';
    elements.password.type = state.passwordVisible ? 'text' : 'password';
    elements.passwordToggle.setAttribute(
      'aria-pressed',
      state.passwordVisible ? 'true' : 'false',
    );
    elements.passwordToggle.setAttribute('aria-label', copy(ariaKey));
    elements.passwordToggleLabel.textContent = copy(labelKey);
  }

  function applyMobileBlockState(elements) {
    elements.mobileBlock.hidden = !state.mobileBlocked;
    elements.card.classList.toggle('is-mobile-blocked', state.mobileBlocked);
    elements.form.setAttribute(
      'aria-disabled',
      state.mobileBlocked ? 'true' : 'false',
    );
  }

  function setLoading(elements, isLoading) {
    state.submitting = isLoading;
    elements.form.setAttribute('aria-busy', isLoading ? 'true' : 'false');
    const disabled =
      isLoading ||
      state.apiConfig === null ||
      state.mobileBlocked;
    elements.submit.disabled = disabled;
    elements.login.disabled = disabled;
    elements.password.disabled = disabled;
    elements.passwordToggle.disabled = disabled;
    elements.submit.classList.toggle('is-loading', isLoading);
    elements.submitLabel.textContent = copy(
      isLoading ? 'form.loading' : 'form.submit',
    );
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

    if (state.submitting) {
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
      const destination = resolvePublicLoginRedirect(
        window.location.search,
        window.location.origin,
      );
      window.location.replace(destination);
    } catch (error) {
      setLoading(elements, false);
      setFeedback(elements, loginErrorKeyFromError(error), true);
    }
  }

  function collectElements() {
    return {
      card: document.querySelector('[data-login-card]'),
      form: document.querySelector('[data-login-form]'),
      login: document.querySelector('[data-login-input]'),
      mobileBlock: document.querySelector('[data-login-mobile-block]'),
      password: document.querySelector('[data-password-input]'),
      passwordToggle: document.querySelector('[data-password-toggle]'),
      passwordToggleLabel: document.querySelector('[data-password-toggle-label]'),
      submit: document.querySelector('[data-login-submit]'),
      submitLabel: document.querySelector('[data-login-submit-label]'),
      feedback: document.querySelector('[data-login-feedback]'),
    };
  }

  function hasRequiredElements(elements) {
    return Object.keys(elements).every((key) => Boolean(elements[key]));
  }

  function initialize() {
    const elements = collectElements();
    if (!hasRequiredElements(elements)) return;

    document.documentElement.classList.add('has-js');
    state.language = applyPublicLanguage({
      dictionary: LOGIN_DICTIONARY,
      language: selectPublicLanguage(),
    });

    setupPublicLanguageSwitcher({
      dictionary: LOGIN_DICTIONARY,
      onChange: (language) => {
        state.language = language;
        updatePasswordToggle(elements);
        applyMobileBlockState(elements);
        setLoading(elements, state.submitting);
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

    if (!state.mobileBlocked) {
      try {
        state.apiConfig = resolvePublicApiConfig(window.SIXAPP_PUBLIC_CONFIG);
      } catch (_) {
        disableForConfigError(elements);
      }
    }

    setLoading(elements, false);
    elements.form.addEventListener('submit', (event) => {
      handleSubmit(elements, event);
    });

    cleanupLegacyFlutterWorker();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initialize);
  } else {
    initialize();
  }
})();
