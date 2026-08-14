import {
  applyPublicLanguage,
  cleanupLegacyFlutterWorker,
  selectPublicLanguage,
  setupPublicLanguageSwitcher,
} from './public-locale.mjs';
import {
  FORGOT_PASSWORD_DICTIONARY,
  FORGOT_PASSWORD_RESEND_COOLDOWN_SECONDS,
  FORGOT_PASSWORD_SUCCESS_LOGIN_PATH,
  FORGOT_PASSWORD_TIMEOUT_MS,
  PublicForgotPasswordValidationError,
  forgotPasswordErrorKeyFromError,
  performForgotPasswordReset,
  performForgotPasswordSendCode,
  performForgotPasswordValidateCode,
  resolvePublicApiConfig,
  validateRecoveryCode,
  validateRecoveryEmail,
  validateRecoveryPasswordFields,
} from './forgot-password-core.mjs';

(function () {
  'use strict';

  const STEP_COPY = Object.freeze({
    identify: Object.freeze({
      title: 'identify.title',
      subtitle: 'identify.subtitle',
    }),
    code: Object.freeze({
      title: 'code.title',
      subtitle: 'code.subtitle',
    }),
    password: Object.freeze({
      title: 'password.title',
      subtitle: 'password.subtitle',
    }),
    success: Object.freeze({
      title: 'success.title',
      subtitle: 'success.body',
    }),
  });

  const state = {
    apiConfig: null,
    language: 'pt',
    step: 'identify',
    email: null,
    codigo: null,
    passwordVisible: false,
    confirmPasswordVisible: false,
    submitting: false,
    action: null,
    feedbackKey: null,
    feedbackType: 'error',
    completed: false,
    resendSecondsLeft: 0,
    resendTimer: null,
  };

  function copy(key) {
    return FORGOT_PASSWORD_DICTIONARY[state.language]?.[key] ||
      FORGOT_PASSWORD_DICTIONARY.pt[key] ||
      key;
  }

  function copyWithParams(key, params = {}) {
    let value = copy(key);
    Object.keys(params).forEach((name) => {
      value = value.replace(`{${name}}`, String(params[name]));
    });
    return value;
  }

  function setFeedback(elements, key, type = 'error', focus = false) {
    state.feedbackKey = key;
    state.feedbackType = type;
    elements.feedback.hidden = false;
    elements.feedback.textContent = copy(key);
    elements.feedback.classList.toggle('is-info', type === 'info');
    elements.feedback.classList.toggle('is-success', type === 'success');
    if (focus) {
      elements.feedback.focus({ preventScroll: false });
    }
  }

  function clearFeedback(elements) {
    state.feedbackKey = null;
    state.feedbackType = 'error';
    elements.feedback.hidden = true;
    elements.feedback.textContent = '';
    elements.feedback.classList.remove('is-info', 'is-success');
  }

  function updateStepCopy(elements) {
    const keys = STEP_COPY[state.step] || STEP_COPY.identify;
    elements.stepTitle.textContent = copy(keys.title);
    elements.stepSubtitle.textContent = copy(keys.subtitle);
  }

  function showStep(elements, step, focusTitle = true) {
    state.step = step;
    elements.cardHeader.hidden = step === 'success';
    elements.progress.hidden = step === 'success';
    elements.panels.forEach((panel) => {
      panel.hidden = panel.getAttribute('data-step-panel') !== step;
    });
    elements.indicators.forEach((indicator) => {
      const isCurrent = indicator.getAttribute('data-step-indicator') === step;
      if (isCurrent) {
        indicator.setAttribute('aria-current', 'step');
      } else {
        indicator.removeAttribute('aria-current');
      }
    });
    updateStepCopy(elements);
    syncDisabled(elements);
    if (focusTitle) {
      elements.stepTitle.focus({ preventScroll: false });
    }
  }

  function updatePasswordToggle(elements, type) {
    const isConfirm = type === 'confirm';
    const visible = isConfirm
      ? state.confirmPasswordVisible
      : state.passwordVisible;
    const input = isConfirm
      ? elements.confirmPassword
      : elements.newPassword;
    const toggle = isConfirm
      ? elements.confirmPasswordToggle
      : elements.passwordToggle;
    const label = isConfirm
      ? elements.confirmPasswordToggleLabel
      : elements.passwordToggleLabel;
    const ariaKey = isConfirm
      ? (visible
        ? 'confirmPassword.hideAria'
        : 'confirmPassword.showAria')
      : (visible ? 'password.hideAria' : 'password.showAria');

    input.type = visible ? 'text' : 'password';
    toggle.setAttribute('aria-pressed', visible ? 'true' : 'false');
    toggle.setAttribute('aria-label', copy(ariaKey));
    label.textContent = copy(visible ? 'password.hide' : 'password.show');
  }

  function resendLabel() {
    if (state.action === 'resend') return copy('action.resendLoading');
    if (state.resendSecondsLeft > 0) {
      return copyWithParams('action.resendCountdown', {
        seconds: state.resendSecondsLeft,
      });
    }
    return copy('action.resend');
  }

  function updateLoadingLabels(elements) {
    elements.sendLabel.textContent = copy(
      state.action === 'send' ? 'identify.loading' : 'identify.submit',
    );
    elements.codeLabel.textContent = copy(
      state.action === 'validate' ? 'code.loading' : 'code.submit',
    );
    elements.passwordLabel.textContent = copy(
      state.action === 'reset' ? 'password.loading' : 'password.submit',
    );
    elements.resend.textContent = resendLabel();
  }

  function syncDisabled(elements) {
    const unavailable = state.apiConfig === null || state.completed;
    const busy = state.submitting;
    const disabled = unavailable || busy;

    elements.identifyForm.setAttribute(
      'aria-busy',
      state.action === 'send' ? 'true' : 'false',
    );
    elements.codeForm.setAttribute(
      'aria-busy',
      state.action === 'validate' || state.action === 'resend'
        ? 'true'
        : 'false',
    );
    elements.passwordForm.setAttribute(
      'aria-busy',
      state.action === 'reset' ? 'true' : 'false',
    );

    elements.email.disabled = disabled || state.step !== 'identify';
    elements.sendSubmit.disabled = disabled || state.step !== 'identify';
    elements.code.disabled = disabled || state.step !== 'code' || !state.email;
    elements.codeSubmit.disabled =
      disabled || state.step !== 'code' || !state.email;
    elements.backEmail.disabled = busy || state.step !== 'code';
    elements.resend.disabled =
      disabled ||
      state.step !== 'code' ||
      !state.email ||
      state.resendSecondsLeft > 0;
    elements.newPassword.disabled =
      disabled || state.step !== 'password' || !state.email || !state.codigo;
    elements.confirmPassword.disabled =
      disabled || state.step !== 'password' || !state.email || !state.codigo;
    elements.passwordSubmit.disabled =
      disabled || state.step !== 'password' || !state.email || !state.codigo;
    elements.backCode.disabled = busy || state.step !== 'password';
    elements.passwordToggle.disabled =
      disabled || state.step !== 'password' || !state.email || !state.codigo;
    elements.confirmPasswordToggle.disabled =
      disabled || state.step !== 'password' || !state.email || !state.codigo;

    elements.sendSubmit.classList.toggle('is-loading', state.action === 'send');
    elements.codeSubmit.classList.toggle(
      'is-loading',
      state.action === 'validate',
    );
    elements.passwordSubmit.classList.toggle(
      'is-loading',
      state.action === 'reset',
    );
    updateLoadingLabels(elements);
  }

  function setLoading(elements, action) {
    state.submitting = Boolean(action);
    state.action = action;
    syncDisabled(elements);
  }

  function disableForConfigError(elements) {
    state.apiConfig = null;
    setLoading(elements, null);
    setFeedback(elements, 'error.config', 'error', false);
  }

  function stopResendTimer() {
    if (state.resendTimer !== null) {
      clearInterval(state.resendTimer);
      state.resendTimer = null;
    }
  }

  function startResendCooldown(elements) {
    stopResendTimer();
    state.resendSecondsLeft = FORGOT_PASSWORD_RESEND_COOLDOWN_SECONDS;
    syncDisabled(elements);
    state.resendTimer = setInterval(() => {
      state.resendSecondsLeft = Math.max(0, state.resendSecondsLeft - 1);
      if (state.resendSecondsLeft === 0) {
        stopResendTimer();
      }
      syncDisabled(elements);
    }, 1000);
  }

  function focusValidationTarget(elements, error) {
    if (!(error instanceof PublicForgotPasswordValidationError)) return;
    if (error.code === 'email') {
      elements.email.focus();
      return;
    }
    if (error.code === 'codeRequired' || error.code === 'codeFormat') {
      elements.code.focus();
      return;
    }
    if (
      error.code === 'passwordRequired' ||
      error.code === 'passwordTooShort' ||
      error.code === 'passwordTooLong'
    ) {
      elements.newPassword.focus();
      return;
    }
    if (error.code === 'passwordMismatch') {
      elements.confirmPassword.focus();
    }
  }

  function clearCodeAndPassword(elements) {
    state.codigo = null;
    elements.code.value = '';
    elements.newPassword.value = '';
    elements.confirmPassword.value = '';
  }

  function clearSensitiveFields(elements) {
    state.email = null;
    state.codigo = null;
    elements.email.value = '';
    elements.code.value = '';
    elements.newPassword.value = '';
    elements.confirmPassword.value = '';
  }

  async function submitSendCode(elements, event) {
    event.preventDefault();

    if (state.submitting) {
      setFeedback(elements, 'error.pending', 'error', true);
      return;
    }

    clearFeedback(elements);
    if (state.apiConfig === null) {
      disableForConfigError(elements);
      return;
    }

    let email;
    try {
      email = validateRecoveryEmail(elements.email.value);
    } catch (error) {
      setFeedback(elements, forgotPasswordErrorKeyFromError(error), 'error');
      focusValidationTarget(elements, error);
      return;
    }

    setLoading(elements, 'send');
    try {
      await performForgotPasswordSendCode({
        apiBaseUrl: state.apiConfig.apiBaseUrl,
        email,
        timeoutMs: FORGOT_PASSWORD_TIMEOUT_MS,
      });
      state.email = email;
      clearCodeAndPassword(elements);
      showStep(elements, 'code');
      setFeedback(elements, 'info.instructionsSent', 'info', false);
      startResendCooldown(elements);
    } catch (error) {
      setLoading(elements, null);
      setFeedback(
        elements,
        forgotPasswordErrorKeyFromError(error),
        'error',
        true,
      );
    } finally {
      if (state.action === 'send') {
        setLoading(elements, null);
      }
    }
  }

  async function submitResendCode(elements) {
    if (state.submitting) {
      setFeedback(elements, 'error.pending', 'error', true);
      return;
    }
    if (state.resendSecondsLeft > 0 || !state.email) return;

    clearFeedback(elements);
    if (state.apiConfig === null) {
      disableForConfigError(elements);
      return;
    }

    setLoading(elements, 'resend');
    try {
      await performForgotPasswordSendCode({
        apiBaseUrl: state.apiConfig.apiBaseUrl,
        email: state.email,
        timeoutMs: FORGOT_PASSWORD_TIMEOUT_MS,
      });
      setFeedback(elements, 'info.resendSent', 'info', false);
      startResendCooldown(elements);
    } catch (error) {
      setFeedback(
        elements,
        forgotPasswordErrorKeyFromError(error),
        'error',
        true,
      );
    } finally {
      setLoading(elements, null);
    }
  }

  async function submitCode(elements, event) {
    event.preventDefault();

    if (state.submitting) {
      setFeedback(elements, 'error.pending', 'error', true);
      return;
    }

    clearFeedback(elements);
    if (state.apiConfig === null) {
      disableForConfigError(elements);
      return;
    }
    if (!state.email) {
      setFeedback(elements, 'error.stateMissing', 'error', true);
      showStep(elements, 'identify', false);
      return;
    }

    let codigo;
    try {
      codigo = validateRecoveryCode(elements.code.value);
    } catch (error) {
      setFeedback(elements, forgotPasswordErrorKeyFromError(error), 'error');
      focusValidationTarget(elements, error);
      return;
    }

    setLoading(elements, 'validate');
    try {
      await performForgotPasswordValidateCode({
        apiBaseUrl: state.apiConfig.apiBaseUrl,
        email: state.email,
        codigo,
        timeoutMs: FORGOT_PASSWORD_TIMEOUT_MS,
      });
      state.codigo = codigo;
      showStep(elements, 'password');
      setFeedback(elements, 'info.codeAccepted', 'info', false);
    } catch (error) {
      setLoading(elements, null);
      elements.code.value = '';
      setFeedback(
        elements,
        forgotPasswordErrorKeyFromError(error),
        'error',
        true,
      );
      elements.code.focus();
    } finally {
      if (state.action === 'validate') {
        setLoading(elements, null);
      }
    }
  }

  async function submitPassword(elements, event) {
    event.preventDefault();

    if (state.submitting) {
      setFeedback(elements, 'error.pending', 'error', true);
      return;
    }

    clearFeedback(elements);
    if (state.apiConfig === null) {
      disableForConfigError(elements);
      return;
    }
    if (!state.email || !state.codigo) {
      setFeedback(elements, 'error.stateMissing', 'error', true);
      showStep(elements, state.email ? 'code' : 'identify', false);
      return;
    }

    try {
      validateRecoveryPasswordFields({
        novaSenha: elements.newPassword.value,
        confirmarSenha: elements.confirmPassword.value,
      });
    } catch (error) {
      setFeedback(elements, forgotPasswordErrorKeyFromError(error), 'error');
      focusValidationTarget(elements, error);
      return;
    }

    setLoading(elements, 'reset');
    try {
      await performForgotPasswordReset({
        apiBaseUrl: state.apiConfig.apiBaseUrl,
        email: state.email,
        codigo: state.codigo,
        novaSenha: elements.newPassword.value,
        confirmarSenha: elements.confirmPassword.value,
        timeoutMs: FORGOT_PASSWORD_TIMEOUT_MS,
      });
      stopResendTimer();
      state.completed = true;
      clearSensitiveFields(elements);
      clearFeedback(elements);
      showStep(elements, 'success');
      elements.successTitle.focus({ preventScroll: false });
    } catch (error) {
      setLoading(elements, null);
      setFeedback(
        elements,
        forgotPasswordErrorKeyFromError(error),
        'error',
        true,
      );
    } finally {
      if (state.action === 'reset') {
        setLoading(elements, null);
      }
    }
  }

  function collectElements() {
    return {
      stepTitle: document.querySelector('[data-forgot-step-title]'),
      stepSubtitle: document.querySelector('[data-forgot-step-subtitle]'),
      cardHeader: document.querySelector('[data-forgot-card-header]'),
      progress: document.querySelector('[data-forgot-progress]'),
      panels: Array.from(document.querySelectorAll('[data-step-panel]')),
      indicators: Array.from(document.querySelectorAll('[data-step-indicator]')),
      feedback: document.querySelector('[data-forgot-feedback]'),
      identifyForm: document.querySelector('[data-forgot-identify-form]'),
      codeForm: document.querySelector('[data-forgot-code-form]'),
      passwordForm: document.querySelector('[data-forgot-password-form]'),
      email: document.querySelector('[data-forgot-email]'),
      sendSubmit: document.querySelector('[data-forgot-send-submit]'),
      sendLabel: document.querySelector('[data-forgot-send-label]'),
      code: document.querySelector('[data-forgot-code]'),
      codeSubmit: document.querySelector('[data-forgot-code-submit]'),
      codeLabel: document.querySelector('[data-forgot-code-label]'),
      backEmail: document.querySelector('[data-forgot-back-email]'),
      resend: document.querySelector('[data-forgot-resend]'),
      newPassword: document.querySelector('[data-forgot-new-password]'),
      confirmPassword: document.querySelector('[data-forgot-confirm-password]'),
      passwordToggle: document.querySelector('[data-forgot-password-toggle]'),
      passwordToggleLabel: document.querySelector('[data-forgot-password-toggle-label]'),
      confirmPasswordToggle: document.querySelector('[data-forgot-confirm-password-toggle]'),
      confirmPasswordToggleLabel: document.querySelector('[data-forgot-confirm-password-toggle-label]'),
      passwordSubmit: document.querySelector('[data-forgot-password-submit]'),
      passwordLabel: document.querySelector('[data-forgot-password-label]'),
      backCode: document.querySelector('[data-forgot-back-code]'),
      successTitle: document.querySelector('[data-forgot-success-title]'),
      login: document.querySelector('[data-forgot-login]'),
    };
  }

  function hasRequiredElements(elements) {
    const requiredKeys = Object.keys(elements);
    return requiredKeys.every((key) => {
      const value = elements[key];
      return Array.isArray(value) ? value.length > 0 : Boolean(value);
    });
  }

  function initialize() {
    const elements = collectElements();
    if (!hasRequiredElements(elements)) return;

    document.documentElement.classList.add('has-js');
    state.language = applyPublicLanguage({
      dictionary: FORGOT_PASSWORD_DICTIONARY,
      language: selectPublicLanguage(),
    });

    setupPublicLanguageSwitcher({
      dictionary: FORGOT_PASSWORD_DICTIONARY,
      onChange: (language) => {
        state.language = language;
        updateStepCopy(elements);
        updatePasswordToggle(elements, 'password');
        updatePasswordToggle(elements, 'confirm');
        if (state.feedbackKey) {
          elements.feedback.textContent = copy(state.feedbackKey);
        }
        syncDisabled(elements);
      },
    });

    updatePasswordToggle(elements, 'password');
    updatePasswordToggle(elements, 'confirm');

    elements.passwordToggle.addEventListener('click', () => {
      state.passwordVisible = !state.passwordVisible;
      updatePasswordToggle(elements, 'password');
      elements.newPassword.focus();
    });

    elements.confirmPasswordToggle.addEventListener('click', () => {
      state.confirmPasswordVisible = !state.confirmPasswordVisible;
      updatePasswordToggle(elements, 'confirm');
      elements.confirmPassword.focus();
    });

    elements.code.addEventListener('input', () => {
      elements.code.value = elements.code.value.replace(/\D/g, '').slice(0, 6);
    });

    elements.backEmail.addEventListener('click', () => {
      stopResendTimer();
      clearCodeAndPassword(elements);
      clearFeedback(elements);
      showStep(elements, 'identify');
    });

    elements.backCode.addEventListener('click', () => {
      clearFeedback(elements);
      elements.newPassword.value = '';
      elements.confirmPassword.value = '';
      showStep(elements, 'code');
    });

    elements.resend.addEventListener('click', () => {
      submitResendCode(elements);
    });

    elements.login.addEventListener('click', () => {
      window.location.replace(FORGOT_PASSWORD_SUCCESS_LOGIN_PATH);
    });

    try {
      state.apiConfig = resolvePublicApiConfig(window.SIXAPP_PUBLIC_CONFIG);
    } catch (_) {
      disableForConfigError(elements);
    }

    showStep(elements, 'identify', false);
    setLoading(elements, null);

    elements.identifyForm.addEventListener('submit', (event) => {
      submitSendCode(elements, event);
    });
    elements.codeForm.addEventListener('submit', (event) => {
      submitCode(elements, event);
    });
    elements.passwordForm.addEventListener('submit', (event) => {
      submitPassword(elements, event);
    });

    cleanupLegacyFlutterWorker();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initialize);
  } else {
    initialize();
  }
})();
