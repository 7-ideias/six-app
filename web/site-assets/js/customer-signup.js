import {
  applyPublicLanguage,
  cleanupLegacyFlutterWorker,
  selectPublicLanguage,
  setupPublicLanguageSwitcher,
} from './public-locale.mjs';
import {
  CUSTOMER_SIGNUP_DICTIONARY,
  buildCustomerSignupPayload,
  calculateCustomerSignupQuality,
  customerSignupErrorKey,
  extractCustomerSignupLink,
  normalizeCustomerSignupValidationResponse,
  resolvePublicApiConfig,
  submitCustomerSignup,
  validateCustomerSignupLink,
} from './customer-signup-core.mjs';

(function () {
  'use strict';

  const state = {
    apiConfig: null,
    link: null,
    language: 'pt',
    step: 0,
    submitting: false,
    loadErrorKey: null,
    feedbackKey: null,
    completed: false,
    validation: null,
  };
  const elements = {
    loading: document.querySelector('[data-customer-loading]'),
    error: document.querySelector('[data-customer-error]'),
    errorMessage: document.querySelector('[data-customer-error-message]'),
    retry: document.querySelector('[data-customer-retry]'),
    card: document.querySelector('[data-customer-card]'),
    form: document.querySelector('[data-customer-form]'),
    steps: [...document.querySelectorAll('[data-customer-step]')],
    feedbacks: [...document.querySelectorAll('[data-customer-feedback], [data-customer-feedback-details]')],
    next: document.querySelector('[data-customer-next]'),
    back: document.querySelector('[data-customer-back]'),
    submitSimple: document.querySelector('[data-customer-submit-simple]'),
    submitComplete: document.querySelector('[data-customer-submit-complete]'),
    submitLabels: [...document.querySelectorAll('[data-customer-submit-label]')],
    success: document.querySelector('[data-customer-success]'),
    successTitle: document.querySelector('#customer-success-title'),
    qualityValue: document.querySelector('[data-quality-value]'),
    qualityLevel: document.querySelector('[data-quality-level]'),
    qualityProgress: document.querySelector('[data-quality-progress]'),
    qualityTrack: document.querySelector('[data-quality-track]'),
    qualitySuggestion: document.querySelector('[data-quality-suggestion]'),
    stepLabel: document.querySelector('[data-step-label]'),
    stepTrack: document.querySelector('[data-step-track]'),
    stepBars: [...document.querySelectorAll('[data-step-bar]')],
    journeyOptions: [...document.querySelectorAll('[data-journey-option]')],
    companySection: document.querySelector('[data-company-section]'),
    companyName: document.querySelector('[data-company-name]'),
    companyTitle: document.querySelector('[data-company-title]'),
    companyDescription: document.querySelector('[data-company-description]'),
    companyAddress: document.querySelector('[data-company-address]'),
    companyContact: document.querySelector('[data-company-contact]'),
    companyContactLinks: document.querySelector('[data-company-contact-links]'),
    companyLogos: [...document.querySelectorAll('[data-company-logo]')],
    companyLogoLarge: document.querySelector('[data-company-logo-large]'),
    companyBrand: document.querySelector('[data-company-brand]'),
    companyContextName: document.querySelector('[data-company-context-name]'),
  };

  function copy(key) { return CUSTOMER_SIGNUP_DICTIONARY[state.language]?.[key] || CUSTOMER_SIGNUP_DICTIONARY.pt[key] || key; }
  function values() {
    const data = new FormData(elements.form);
    return Object.fromEntries([...data.entries()].map(([key, value]) => [key, String(value)]));
  }
  function normalizedValues() { return { ...values(), consentimento: elements.form.elements.consentimento.checked }; }
  function mode() { return values().tipoCadastro === 'COMPLETO' ? 'COMPLETO' : 'SIMPLES'; }
  function companyDisplayName() {
    return state.validation?.company?.displayName || copy('title');
  }

  function customerHasDetailedData(customer) {
    if (!customer) return false;
    return customer.tipoCadastro === 'COMPLETO'
      || ['cep', 'logradouro', 'numero', 'complemento', 'bairro', 'cidade', 'uf', 'observacoes']
        .some((key) => String(customer[key] || '').trim());
  }

  function applyExistingCustomerData() {
    const customer = state.validation?.customer;
    if (!customer) return;
    const form = elements.form.elements;
    form.documentoOriginal.value = customer.documento || state.link.documento || '';
    form.tipoPessoa.value = customer.tipoPessoa === 'PJ' ? 'PJ' : 'PF';
    form.nome.value = customer.nome;
    form.documento.value = customer.documento;
    form.telefone.value = customer.telefone;
    form.email.value = customer.email;
    form.cep.value = customer.cep;
    form.logradouro.value = customer.logradouro;
    form.numero.value = customer.numero;
    form.complemento.value = customer.complemento;
    form.bairro.value = customer.bairro;
    form.cidade.value = customer.cidade;
    form.uf.value = customer.uf;
    form.observacoes.value = customer.observacoes;
    form.tipoCadastro.value = customerHasDetailedData(customer) ? 'COMPLETO' : 'SIMPLES';
  }

  function safeExternalUrl(value) {
    try {
      const url = new URL(String(value || ''));
      return ['http:', 'https:'].includes(url.protocol) ? url.toString() : '';
    } catch (_) {
      return '';
    }
  }

  function addContactLink(container, { href, label, ariaLabel }) {
    if (!href || !label) return;
    const link = document.createElement('a');
    link.href = href;
    link.textContent = label;
    link.setAttribute('aria-label', ariaLabel || label);
    if (href.startsWith('http')) {
      link.target = '_blank';
      link.rel = 'noopener noreferrer';
    }
    container.append(link);
  }

  function setMetaContent(selector, value) {
    const node = document.querySelector(selector);
    if (node && value) node.setAttribute('content', value);
  }

  function setCompanyLogo(image, logo, fallback) {
    if (!image) return;
    if (logo) {
      image.hidden = false;
      image.src = logo;
      image.alt = fallback;
      return;
    }
    image.hidden = true;
    image.removeAttribute('src');
    image.alt = '';
  }

  function renderCompanyIdentity() {
    const company = state.validation?.company;
    if (!company || !companyDisplayName()) {
      elements.companySection.hidden = true;
      return;
    }

    const displayName = company.displayName || copy('title');
    const description = copy('company.description');
    elements.companyBrand.setAttribute('aria-label', displayName);
    elements.companyName.textContent = displayName;
    elements.companyTitle.textContent = displayName;
    elements.companyContextName.textContent = displayName;
    elements.companyDescription.hidden = !description;
    elements.companyDescription.textContent = description;
    elements.companyAddress.hidden = !company.address;
    elements.companyAddress.textContent = company.address;
    elements.companyContactLinks.textContent = '';

    const whatsappDigits = company.whatsapp.replace(/\D/g, '');
    const phoneDigits = company.phone.replace(/[^\d+]/g, '');
    addContactLink(elements.companyContactLinks, {
      href: whatsappDigits ? `https://wa.me/${whatsappDigits}` : '',
      label: company.whatsapp,
      ariaLabel: `WhatsApp ${company.whatsapp}`,
    });
    addContactLink(elements.companyContactLinks, {
      href: phoneDigits ? `tel:${phoneDigits}` : '',
      label: company.phone,
    });
    addContactLink(elements.companyContactLinks, {
      href: company.email ? `mailto:${company.email}` : '',
      label: company.email,
    });
    const site = safeExternalUrl(company.site);
    addContactLink(elements.companyContactLinks, {
      href: site,
      label: site ? new URL(site).host : '',
    });
    elements.companyContact.hidden =
      elements.companyContactLinks.childElementCount === 0;

    elements.companyLogos.forEach((image) => {
      setCompanyLogo(image, company.logoBase64, displayName);
    });
    setCompanyLogo(elements.companyLogoLarge, company.logoBase64, displayName);
    elements.companySection.hidden = false;

    const title = `${displayName} • ${copy('title')}`;
    const descriptionText = description || copy('description');
    document.title = title;
    setMetaContent('meta[name="description"]', descriptionText);
    setMetaContent('meta[property="og:title"]', title);
    setMetaContent('meta[property="og:description"]', descriptionText);
    setMetaContent('meta[name="twitter:title"]', title);
    setMetaContent('meta[name="twitter:description"]', descriptionText);
  }

  function hidePrimaryStates() { elements.loading.hidden = true; elements.error.hidden = true; elements.card.hidden = true; }
  function showLoading() { hidePrimaryStates(); elements.loading.hidden = false; }
  function showLoadError(key) { state.loadErrorKey = key; hidePrimaryStates(); elements.errorMessage.textContent = copy(key); elements.error.hidden = false; }
  function showForm() { hidePrimaryStates(); elements.card.hidden = false; elements.form.hidden = false; elements.success.hidden = true; renderJourney(); }
  function clearFeedback() { state.feedbackKey = null; elements.feedbacks.forEach((node) => { node.hidden = true; node.textContent = ''; }); }
  function setFeedback(key, focus = true) {
    state.feedbackKey = key;
    const node = state.step === 1 ? elements.feedbacks[1] : elements.feedbacks[0];
    node.textContent = copy(key); node.hidden = false;
    if (focus) node.focus({ preventScroll: false });
  }

  function qualityLevel(percentage) {
    if (percentage >= 90) return 'quality.excellent';
    if (percentage >= 70) return 'quality.detailed';
    if (percentage >= 40) return 'quality.essential';
    return 'quality.initial';
  }

  function renderQuality() {
    const quality = calculateCustomerSignupQuality(normalizedValues());
    elements.qualityValue.textContent = `${quality.percentage}%`;
    elements.qualityLevel.textContent = copy(qualityLevel(quality.percentage));
    elements.qualityProgress.style.width = `${quality.percentage}%`;
    elements.qualityTrack.setAttribute('aria-valuenow', String(quality.percentage));
    elements.qualitySuggestion.textContent = quality.missing.length ? copy(`quality.${quality.missing[0]}`) : copy('quality.complete');
  }

  function renderJourney() {
    const complete = mode() === 'COMPLETO';
    if (!complete) state.step = 0;
    elements.journeyOptions.forEach((option) => option.classList.toggle('is-selected', option.dataset.journeyOption === mode()));
    elements.steps.forEach((step) => { step.hidden = Number(step.dataset.customerStep) !== state.step; });
    elements.next.hidden = !complete;
    elements.submitSimple.hidden = complete;
    elements.stepBars[1].hidden = !complete;
    elements.stepTrack.classList.toggle('is-single', !complete);
    elements.stepBars.forEach((bar, index) => bar.classList.toggle('is-active', index <= state.step));
    elements.stepLabel.textContent = copy(state.step === 1 ? 'step.details' : complete ? 'step.essential.complete' : 'step.essential.simple');
    renderQuality();
  }

  function rerenderDynamicCopy() {
    if (state.loadErrorKey && !elements.error.hidden) elements.errorMessage.textContent = copy(state.loadErrorKey);
    if (state.feedbackKey) setFeedback(state.feedbackKey, false);
    elements.submitLabels.forEach((label) => { label.textContent = copy(state.submitting ? 'form.loading' : 'form.submit'); });
    renderCompanyIdentity();
    renderJourney();
  }

  function setSubmitting(value) {
    state.submitting = value;
    elements.form.setAttribute('aria-busy', value ? 'true' : 'false');
    [...elements.form.elements].forEach((element) => { element.disabled = value; });
    elements.submitSimple.classList.toggle('is-loading', value);
    elements.submitComplete.classList.toggle('is-loading', value);
    elements.submitLabels.forEach((label) => { label.textContent = copy(value ? 'form.loading' : 'form.submit'); });
  }

  function validateEssentials() {
    const name = elements.form.elements.nome;
    const documentInput = elements.form.elements.documento;
    const consent = elements.form.elements.consentimento;
    const email = elements.form.elements.email;
    if (!name.value.trim() || !documentInput.value.trim() || !consent.checked) {
      setFeedback('error.required');
      (name.value.trim() ? documentInput.value.trim() ? consent : documentInput : name).focus();
      return false;
    }
    if (email.value.trim() && !email.checkValidity()) {
      setFeedback('error.emailInvalid'); email.focus(); return false;
    }
    return true;
  }

  async function loadLink() {
    showLoading(); state.loadErrorKey = null;
    try {
      state.validation = normalizeCustomerSignupValidationResponse(
        await validateCustomerSignupLink({
          apiBaseUrl: state.apiConfig.apiBaseUrl,
          link: state.link,
        }),
      );
      applyExistingCustomerData();
      renderCompanyIdentity();
      showForm();
    } catch (error) { showLoadError(customerSignupErrorKey(error)); }
  }

  async function submit(event) {
    event.preventDefault();
    if (state.submitting) { setFeedback('error.pending'); return; }
    clearFeedback();
    if (!validateEssentials()) { state.step = 0; renderJourney(); return; }
    try {
      const currentValues = normalizedValues();
      buildCustomerSignupPayload(currentValues, state.link);
      setSubmitting(true);
      await submitCustomerSignup({ apiBaseUrl: state.apiConfig.apiBaseUrl, link: state.link, values: currentValues });
      state.completed = true; elements.form.hidden = true; elements.success.hidden = false;
      elements.successTitle.focus({ preventScroll: false });
    } catch (error) { setFeedback(customerSignupErrorKey(error)); }
    finally { if (!state.completed) setSubmitting(false); }
  }

  function initialize() {
    state.language = applyPublicLanguage({ dictionary: CUSTOMER_SIGNUP_DICTIONARY, language: selectPublicLanguage() });
    setupPublicLanguageSwitcher({ dictionary: CUSTOMER_SIGNUP_DICTIONARY, onChange(language) { state.language = language; rerenderDynamicCopy(); } });
    cleanupLegacyFlutterWorker();
    elements.form.addEventListener('input', () => { clearFeedback(); renderQuality(); });
    elements.form.addEventListener('change', () => { clearFeedback(); renderJourney(); });
    elements.form.addEventListener('submit', submit);
    elements.next.addEventListener('click', () => { clearFeedback(); if (!validateEssentials()) return; state.step = 1; renderJourney(); elements.stepLabel.scrollIntoView({ behavior: 'smooth', block: 'center' }); });
    elements.back.addEventListener('click', () => { clearFeedback(); state.step = 0; renderJourney(); });
    elements.retry.addEventListener('click', loadLink);

    try {
      state.apiConfig = resolvePublicApiConfig(window.SIXAPP_PUBLIC_CONFIG);
      state.link = extractCustomerSignupLink(window.location.search);
      elements.form.elements.documentoOriginal.value = state.link.documento;
      elements.form.elements.tipoPessoa.value = state.link.tipoPessoa;
      elements.form.elements.documento.value = state.link.documento;
    } catch (error) {
      showLoadError(customerSignupErrorKey(error)); elements.retry.hidden = true; return;
    }
    renderJourney(); loadLink();
  }

  initialize();
})();
