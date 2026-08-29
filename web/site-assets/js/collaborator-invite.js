import {
  applyPublicLanguage,
  cleanupLegacyFlutterWorker,
  selectPublicLanguage,
  setupPublicLanguageSwitcher,
} from './public-locale.mjs';
import {
  COLLABORATOR_INVITE_DICTIONARY,
  collaboratorInviteErrorKeyFromError,
  collaboratorInviteStatusKey,
  confirmCollaboratorInviteEmail,
  extractCollaboratorInviteCode,
  fetchCollaboratorInvite,
  normalizeCollaboratorInviteEmail,
  resolvePublicApiConfig,
} from './collaborator-invite-core.mjs';

(function () {
  'use strict';

  const state = {
    apiConfig: null,
    code: null,
    invite: null,
    language: 'pt',
    errorKey: null,
    submitting: false,
    confirmed: false,
  };

  const elements = {
    loading: document.querySelector('[data-invite-loading]'),
    error: document.querySelector('[data-invite-error]'),
    errorMessage: document.querySelector('[data-invite-error-message]'),
    retry: document.querySelector('[data-invite-retry]'),
    card: document.querySelector('[data-invite-card]'),
    title: document.querySelector('[data-invite-title]'),
    company: document.querySelector('[data-invite-company]'),
    status: document.querySelector('[data-invite-status]'),
    expires: document.querySelector('[data-invite-expires]'),
    form: document.querySelector('[data-invite-form]'),
    email: document.querySelector('[data-invite-email]'),
    feedback: document.querySelector('[data-invite-feedback]'),
    submit: document.querySelector('[data-invite-submit]'),
    submitLabel: document.querySelector('[data-invite-submit-label]'),
    success: document.querySelector('[data-invite-success]'),
    successTitle: document.querySelector('#invite-success-title'),
  };

  function copy(key) {
    return COLLABORATOR_INVITE_DICTIONARY[state.language]?.[key] ||
      COLLABORATOR_INVITE_DICTIONARY.pt[key] ||
      key;
  }

  function hidePrimaryStates() {
    elements.loading.hidden = true;
    elements.error.hidden = true;
    elements.card.hidden = true;
  }

  function showLoading() {
    hidePrimaryStates();
    elements.loading.hidden = false;
  }

  function showLoadError(key) {
    state.errorKey = key;
    hidePrimaryStates();
    elements.errorMessage.textContent = copy(key);
    elements.error.hidden = false;
  }

  function clearFeedback() {
    state.errorKey = null;
    elements.feedback.hidden = true;
    elements.feedback.textContent = '';
  }

  function setFeedback(key, focus = false) {
    state.errorKey = key;
    elements.feedback.textContent = copy(key);
    elements.feedback.hidden = false;
    if (focus) elements.feedback.focus({ preventScroll: false });
  }

  function formatExpiration(value) {
    const date = new Date(value);
    if (!value || Number.isNaN(date.getTime())) return '—';
    const locale = state.language === 'pt'
      ? 'pt-BR'
      : state.language === 'es' ? 'es-ES' : 'en-US';
    return new Intl.DateTimeFormat(locale, {
      dateStyle: 'medium',
      timeStyle: 'short',
    }).format(date);
  }

  function renderInvite() {
    if (!state.invite) return;
    const name = state.invite.nomeConvidado.trim();
    elements.title.textContent = name
      ? copy('invite.titleNamed').replace('{name}', name)
      : copy('invite.title');
    elements.company.textContent = state.invite.nomeFantasia ||
      state.invite.idUnicoDaEmpresa ||
      '—';
    elements.status.textContent = copy(
      state.confirmed
        ? 'status.confirmed'
        : collaboratorInviteStatusKey(state.invite.status),
    );
    elements.status.classList.toggle('is-confirmed', state.confirmed);
    elements.expires.textContent = formatExpiration(state.invite.expiraEm);
    elements.form.hidden = state.confirmed;
    elements.success.hidden = !state.confirmed;
    hidePrimaryStates();
    elements.card.hidden = false;
  }

  function rerenderDynamicCopy() {
    if (state.invite) {
      renderInvite();
    } else if (state.errorKey && !elements.error.hidden) {
      elements.errorMessage.textContent = copy(state.errorKey);
    }
    if (state.errorKey && !elements.feedback.hidden) {
      elements.feedback.textContent = copy(state.errorKey);
    }
    elements.submitLabel.textContent = copy(
      state.submitting ? 'form.loading' : 'form.submit',
    );
  }

  function setSubmitting(value) {
    state.submitting = value;
    elements.form.setAttribute('aria-busy', value ? 'true' : 'false');
    elements.email.disabled = value;
    elements.submit.disabled = value;
    elements.submit.classList.toggle('is-loading', value);
    elements.submitLabel.textContent = copy(
      value ? 'form.loading' : 'form.submit',
    );
  }

  async function loadInvite() {
    showLoading();
    state.invite = null;
    state.confirmed = false;
    state.errorKey = null;
    try {
      state.invite = await fetchCollaboratorInvite({
        apiBaseUrl: state.apiConfig.apiBaseUrl,
        code: state.code,
      });
      state.confirmed = ['EMAIL_CONFIRMADO', 'ACEITO'].includes(
        state.invite.status.trim().toUpperCase(),
      );
      renderInvite();
    } catch (error) {
      showLoadError(collaboratorInviteErrorKeyFromError(error));
    }
  }

  async function submitConfirmation(event) {
    event.preventDefault();
    if (state.submitting) {
      setFeedback('error.pending');
      return;
    }

    clearFeedback();
    try {
      const email = normalizeCollaboratorInviteEmail(elements.email.value);
      setSubmitting(true);
      await confirmCollaboratorInviteEmail({
        apiBaseUrl: state.apiConfig.apiBaseUrl,
        code: state.code,
        email,
      });
      state.confirmed = true;
      elements.email.value = '';
      renderInvite();
      elements.successTitle.focus({ preventScroll: false });
    } catch (error) {
      setFeedback(collaboratorInviteErrorKeyFromError(error), true);
      if (error && ['emailRequired', 'emailInvalid'].includes(error.code)) {
        elements.email.focus();
      }
    } finally {
      setSubmitting(false);
    }
  }

  function initialize() {
    state.language = applyPublicLanguage({
      dictionary: COLLABORATOR_INVITE_DICTIONARY,
      language: selectPublicLanguage(),
    });
    setupPublicLanguageSwitcher({
      dictionary: COLLABORATOR_INVITE_DICTIONARY,
      onChange(language) {
        state.language = language;
        rerenderDynamicCopy();
      },
    });
    cleanupLegacyFlutterWorker();

    elements.form.addEventListener('submit', submitConfirmation);
    elements.retry.addEventListener('click', loadInvite);
    elements.email.addEventListener('input', clearFeedback);

    try {
      state.apiConfig = resolvePublicApiConfig(window.SIXAPP_PUBLIC_CONFIG);
      state.code = extractCollaboratorInviteCode(window.location.pathname);
    } catch (error) {
      showLoadError(collaboratorInviteErrorKeyFromError(error));
      elements.retry.hidden = true;
      return;
    }

    loadInvite();
  }

  initialize();
})();
