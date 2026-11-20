import {
  applyPublicLanguage,
  cleanupLegacyFlutterWorker,
  selectPublicLanguage,
  setupPublicLanguageSwitcher,
} from './public-locale.mjs';
import {
  COLLABORATOR_INVITE_DICTIONARY,
  collaboratorInviteAndroidIntentUrl,
  collaboratorInviteDeepLink,
  collaboratorInviteErrorKeyFromError,
  collaboratorInviteIsMobile,
  collaboratorInvitePlatform,
  collaboratorInviteStoreUrls,
  collaboratorInviteStatusKey,
  postInviteStep,
  acceptWithWebSession,
  extractCollaboratorInviteCode,
  fetchCollaboratorInvite,

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
    step: 'send',
    proof: null,
    email: '',
    switchAccount: false,
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
    otp: document.querySelector('#otp'),
    password: document.querySelector('#new-password'),
    repeat: document.querySelector('#repeat'),
    show: document.querySelector('[data-show]'),
    resend: document.querySelector('[data-resend]'),
    startApp: document.querySelector('[data-mobile-start]'),
    destination: document.querySelector('[data-invite-destination]'),
    feedback: document.querySelector('[data-invite-feedback]'),
    submit: document.querySelector('[data-invite-submit]'),
    submitLabel: document.querySelector('[data-invite-submit-label]'),
    success: document.querySelector('[data-invite-success]'),
    successTitle: document.querySelector('#invite-success-title'),
    mobileHandoff: document.querySelector('[data-invite-mobile-handoff]'),
    openApp: document.querySelector('[data-invite-open-app]'),
    androidStore: document.querySelector('[data-invite-android-store]'),
    iosStore: document.querySelector('[data-invite-ios-store]'),
  };

  function isMobileInviteFlow() {
    return collaboratorInviteIsMobile(window);
  }

  function storeUrls() {
    return collaboratorInviteStoreUrls(window.SIXAPP_PUBLIC_CONFIG || {});
  }

  function preferredStoreUrl() {
    const urls = storeUrls();
    return collaboratorInvitePlatform(navigator) === 'ios' ? urls.ios : urls.android;
  }

  function appOpenUrl() {
    const platform = collaboratorInvitePlatform(navigator);
    if (platform === 'android') {
      return collaboratorInviteAndroidIntentUrl({
        code: state.code,
        storeUrl: preferredStoreUrl(),
      });
    }
    return collaboratorInviteDeepLink(state.code);
  }

  function openAppOrStore() {
    if (!state.code) return;
    let target = appOpenUrl();
    if (state.confirmed) {
      const query = new URLSearchParams({ login: '1', email: state.email });
      target = target.replace(/(#Intent|$)/, '?' + query + '$1');
    }
    window.location.href = target;
  }

  function configureMobileHandoff() {
    const urls = storeUrls();
    elements.androidStore.href = urls.android;
    elements.iosStore.href = urls.ios;
    elements.mobileHandoff.hidden = !isMobileInviteFlow();
  }

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
        ? 'status.accepted'
        : collaboratorInviteStatusKey(state.invite.status),
    );
    elements.status.classList.toggle('is-confirmed', state.confirmed);
    elements.destination.textContent = state.invite.emailConvidado;
    document.querySelector('[data-step="code"]').hidden = state.step !== 'code';
    document.querySelector('[data-step="password"]').hidden = state.step !== 'password';
    elements.startApp.hidden = !isMobileInviteFlow() || state.confirmed;
    elements.submitLabel.textContent = stepLabel();
    elements.expires.textContent = formatExpiration(state.invite.expiraEm);
    elements.form.hidden = state.confirmed;
    elements.success.hidden = !state.confirmed;
    configureMobileHandoff();
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
    elements.submitLabel.textContent = stepLabel();
  }

  function stepLabel() {
    if (state.submitting) return copy('form.loading');
    const key = {send: 'send', code: 'confirm', password: 'save', existing: state.switchAccount ? 'signIn' : 'accept'};
    return copy('access.' + key[state.step]);
  }

  function setSubmitting(value) {
    state.submitting = value;
    elements.form.setAttribute('aria-busy', String(value));
    for (const input of elements.form.elements) input.disabled = value;
    elements.submit.classList.toggle('is-loading', value);
    elements.submitLabel.textContent = stepLabel();
  }

  function loginUrl(existing) {
    const url = new URL('/login', window.location.origin);
    url.searchParams.set('origem', 'convite');
    if (existing) url.searchParams.set('convite', state.code);
    if (state.email) url.hash = new URLSearchParams({ email: state.email }).toString();
    return url.toString();
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
      state.step = state.invite.contaExistente ? 'existing' : 'send';
      renderInvite();
    } catch (error) {
      showLoadError(collaboratorInviteErrorKeyFromError(error));
    }
  }

  function post(step, body) {
    return postInviteStep({ apiBaseUrl: state.apiConfig.apiBaseUrl, code: state.code, step, body, language: state.language });
  }

  async function submitConfirmation(event) {
    event.preventDefault();
    if (state.submitting) return;
    clearFeedback();
    setSubmitting(true);
    try {
      if (state.step === 'send' || event.currentTarget === elements.resend) {
        await post('enviar-codigo');
        state.step = 'code';
        elements.otp.value = '';
      } else if (state.step === 'code') {
        if (!/^[0-9]{6}$/.test(elements.otp.value)) return setFeedback('access.invalid', true);
        const result = await post('confirmar-email', { codigo: elements.otp.value });
        state.proof = result.prova;
        state.email = result.email;
        elements.otp.value = '';
        state.step = 'password';
      } else if (state.step === 'password') {
        const senha = elements.password.value;
        if (!senha.trim() || senha.length < 8 || senha.length > 64) return setFeedback('access.length', true);
        if (senha !== elements.repeat.value) return setFeedback('access.mismatch', true);
        await post('criar-senha', { prova: state.proof, senha });
        elements.repeat.value = elements.password.value = '';
        state.proof = null;
        state.confirmed = true;
        elements.success.querySelector('a[href="/login"]').href = loginUrl(false);
        if (!isMobileInviteFlow()) window.location.replace(loginUrl(false));
      } else if (state.switchAccount) {
        window.location.assign(loginUrl(true));
      } else {
        await acceptWithWebSession({ apiBaseUrl: state.apiConfig.apiBaseUrl, code: state.code });
        window.location.replace('/app');
      }
      renderInvite();
    } catch (error) {
      if (state.step === 'existing' && error.status === 401) {
        window.location.assign(loginUrl(true));
      } else {
        if (error.backendCode === 'CONVITE_EMAIL_DIVERGENTE') state.switchAccount = true;
        if (error.backendCode === 'CONVITE_VERIFIQUE_NOVAMENTE') state.step = 'send';
        if (error.backendCode === 'CONVITE_ENTRAR_COM_CONTA') state.step = 'existing';
        renderInvite();
        setFeedback(collaboratorInviteErrorKeyFromError(error), true);
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
    elements.form.addEventListener('input', clearFeedback);
    elements.resend.addEventListener('click', submitConfirmation);
    elements.startApp.addEventListener('click', openAppOrStore);
    elements.show.addEventListener('change', () => {
      elements.repeat.type = elements.password.type = elements.show.checked ? 'text' : 'password';
    });
    elements.openApp.addEventListener('click', openAppOrStore);
    elements.androidStore.addEventListener('click', () => {
      elements.androidStore.href = storeUrls().android;
    });
    elements.iosStore.addEventListener('click', () => {
      elements.iosStore.href = storeUrls().ios;
    });

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
