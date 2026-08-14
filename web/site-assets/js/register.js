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

(function () {
  'use strict';

  const state = {
    apiConfig: null,
    language: 'pt',
    passwordVisible: false,
    confirmPasswordVisible: false,
    submitting: false,
    feedbackKey: null,
    mismatchVisible: false,
    completed: false,
  };

  function copy(key) {
    return REGISTER_DICTIONARY[state.language]?.[key] ||
      REGISTER_DICTIONARY.pt[key] ||
      key;
  }

  function setFeedback(elements, key, focus = false) {
    state.feedbackKey = key;
    elements.feedback.hidden = false;
    elements.feedback.textContent = copy(key);
    if (focus) {
      elements.feedback.focus({ preventScroll: false });
    }
  }

  function clearFeedback(elements) {
    state.feedbackKey = null;
    elements.feedback.hidden = true;
    elements.feedback.textContent = '';
  }

  function updatePasswordToggle(elements, type) {
    const isConfirm = type === 'confirm';
    const visible = isConfirm
      ? state.confirmPasswordVisible
      : state.passwordVisible;
    const input = isConfirm ? elements.confirmPassword : elements.password;
    const toggle = isConfirm
      ? elements.confirmPasswordToggle
      : elements.passwordToggle;
    const label = isConfirm
      ? elements.confirmPasswordToggleLabel
      : elements.passwordToggleLabel;
    const textKey = visible ? 'form.password.hide' : 'form.password.show';
    const ariaKey = isConfirm
      ? (visible
        ? 'form.confirmPassword.hideAria'
        : 'form.confirmPassword.showAria')
      : (visible ? 'form.password.hideAria' : 'form.password.showAria');

    input.type = visible ? 'text' : 'password';
    toggle.setAttribute('aria-pressed', visible ? 'true' : 'false');
    toggle.setAttribute('aria-label', copy(ariaKey));
    label.textContent = copy(textKey);
  }

  function updateMismatch(elements) {
    const hasConfirmation = elements.confirmPassword.value.length > 0;
    const mismatched = hasConfirmation &&
      elements.password.value !== elements.confirmPassword.value;
    state.mismatchVisible = mismatched;
    elements.passwordMatchFeedback.hidden = !mismatched;
    elements.passwordMatchFeedback.textContent = mismatched
      ? copy('error.passwordMismatch')
      : '';
  }

  function setLoading(elements, isLoading) {
    state.submitting = isLoading;
    elements.form.setAttribute('aria-busy', isLoading ? 'true' : 'false');
    const disabled = isLoading || state.apiConfig === null || state.completed;
    elements.submit.disabled = disabled;
    elements.login.disabled = disabled;
    elements.password.disabled = disabled;
    elements.confirmPassword.disabled = disabled;
    elements.terms.disabled = disabled;
    elements.passwordToggle.disabled = disabled;
    elements.confirmPasswordToggle.disabled = disabled;
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

  function focusValidationTarget(elements, error) {
    if (!(error instanceof PublicRegisterValidationError)) return;
    if (error.code === 'terms') {
      elements.terms.focus();
      return;
    }
    if (error.code === 'passwordTooShort') {
      elements.password.focus();
      return;
    }
    if (error.code === 'passwordMismatch') {
      elements.confirmPassword.focus();
      return;
    }
    if (!elements.login.value.trim()) {
      elements.login.focus();
      return;
    }
    if (!elements.password.value) {
      elements.password.focus();
      return;
    }
    elements.confirmPassword.focus();
  }

  function validateForm(elements) {
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

  function clearSensitiveFields(elements) {
    elements.login.value = '';
    elements.password.value = '';
    elements.confirmPassword.value = '';
    elements.terms.checked = false;
    updateMismatch(elements);
  }

  function showSuccess(elements) {
    state.completed = true;
    clearSensitiveFields(elements);
    clearFeedback(elements);
    setLoading(elements, false);
    elements.formCard.hidden = true;
    elements.successCard.hidden = false;
    elements.successTitle.focus({ preventScroll: false });
  }

  async function handleSubmit(elements, event) {
    event.preventDefault();

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
      await performPublicRegister({
        apiBaseUrl: state.apiConfig.apiBaseUrl,
        login: values.login,
        senha: values.senha,
        confirmarSenha: elements.confirmPassword.value,
        aceitaTermos: elements.terms.checked,
        timeoutMs: REGISTER_TIMEOUT_MS,
      });
      showSuccess(elements);
    } catch (error) {
      setLoading(elements, false);
      setFeedback(elements, registerErrorKeyFromError(error), true);
    }
  }

  function collectElements() {
    return {
      formCard: document.querySelector('[data-register-form-card]'),
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
      dictionary: REGISTER_DICTIONARY,
      language: selectPublicLanguage(),
    });

    setupPublicLanguageSwitcher({
      dictionary: REGISTER_DICTIONARY,
      onChange: (language) => {
        state.language = language;
        updatePasswordToggle(elements, 'password');
        updatePasswordToggle(elements, 'confirm');
        updateMismatch(elements);
        if (state.feedbackKey) {
          elements.feedback.textContent = copy(state.feedbackKey);
        }
        setLoading(elements, state.submitting);
      },
    });

    updatePasswordToggle(elements, 'password');
    updatePasswordToggle(elements, 'confirm');

    elements.passwordToggle.addEventListener('click', () => {
      state.passwordVisible = !state.passwordVisible;
      updatePasswordToggle(elements, 'password');
      elements.password.focus();
    });

    elements.confirmPasswordToggle.addEventListener('click', () => {
      state.confirmPasswordVisible = !state.confirmPasswordVisible;
      updatePasswordToggle(elements, 'confirm');
      elements.confirmPassword.focus();
    });

    elements.password.addEventListener('input', () => updateMismatch(elements));
    elements.confirmPassword.addEventListener(
      'input',
      () => updateMismatch(elements),
    );

    elements.successLogin.addEventListener('click', () => {
      window.location.replace(REGISTER_SUCCESS_LOGIN_PATH);
    });

    try {
      state.apiConfig = resolvePublicApiConfig(window.SIXAPP_PUBLIC_CONFIG);
    } catch (_) {
      disableForConfigError(elements);
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
