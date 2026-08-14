import {
  applyPublicLanguage,
  cleanupLegacyFlutterWorker,
  selectPublicLanguage,
  setupPublicLanguageSwitcher,
} from './public-locale.mjs';
import {
  CHECKOUT_DICTIONARY,
  buildCheckoutPayload,
  checkoutErrorKeyFromError,
  getCheckoutPlanFromSearch,
  hasUnsafeCheckoutPriceParam,
  loadPublicCheckoutPlans,
  resolveSelectedCheckoutPlan,
  validateCheckoutPaymentMethod,
} from './checkout-core.mjs';

(function () {
  'use strict';

  const state = {
    language: 'pt',
    plans: [],
    selectedPlanId: '',
    feedbackKey: null,
    loading: false,
  };

  function copy(key) {
    return CHECKOUT_DICTIONARY[state.language]?.[key] ||
      CHECKOUT_DICTIONARY.pt[key] ||
      key;
  }

  function collectElements() {
    return {
      form: document.querySelector('[data-checkout-form]'),
      plans: document.querySelector('[data-checkout-plans]'),
      loading: document.querySelector('[data-checkout-loading]'),
      feedback: document.querySelector('[data-checkout-feedback]'),
      payload: document.querySelector('[data-checkout-payload]'),
      submit: document.querySelector('[data-checkout-submit]'),
      summaryPlan: document.querySelector('[data-summary-plan]'),
      summaryPrice: document.querySelector('[data-summary-price]'),
      summaryCadence: document.querySelector('[data-summary-cadence]'),
    };
  }

  function hasRequiredElements(elements) {
    return Boolean(
      elements.form &&
      elements.plans &&
      elements.loading &&
      elements.feedback &&
      elements.payload &&
      elements.submit &&
      elements.summaryPlan &&
      elements.summaryPrice &&
      elements.summaryCadence,
    );
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

  function setLoading(elements, loading) {
    state.loading = loading;
    elements.form.setAttribute('aria-busy', loading ? 'true' : 'false');
    elements.loading.hidden = !loading;
    elements.submit.disabled = loading || state.plans.length === 0;
  }

  function getSelectedPlan() {
    return state.plans.find((plan) => plan.id === state.selectedPlanId) || null;
  }

  function updateSummary(elements) {
    const selected = getSelectedPlan();
    elements.summaryPlan.textContent = selected?.name || '-';
    elements.summaryPrice.textContent = selected?.price || '-';
    elements.summaryCadence.textContent = selected?.cadence || '-';
  }

  function renderFeatures(plan, target) {
    if (!plan.features.length) return;

    const list = document.createElement('ul');
    list.className = 'plan-features';
    for (const feature of plan.features) {
      const item = document.createElement('li');
      item.textContent = feature;
      list.append(item);
    }
    target.append(list);
  }

  function createPlanOption(plan, elements) {
    const label = document.createElement('label');
    label.className = 'plan-option';

    const input = document.createElement('input');
    input.type = 'radio';
    input.name = 'plan';
    input.value = plan.id;
    input.checked = plan.id === state.selectedPlanId;

    const body = document.createElement('span');
    const title = document.createElement('span');
    title.className = 'plan-option-title';

    const name = document.createElement('strong');
    name.textContent = plan.name;
    title.append(name);

    if (plan.featured) {
      const featured = document.createElement('span');
      featured.className = 'plan-featured';
      featured.textContent = copy('plans.featured');
      title.append(featured);
    }

    const price = document.createElement('span');
    price.className = 'plan-price';
    price.textContent = `${plan.price} ${plan.cadence}`.trim();

    const pitch = document.createElement('span');
    pitch.className = 'plan-pitch';
    pitch.textContent = plan.pitch;

    body.append(title, price);
    if (plan.pitch) {
      body.append(pitch);
    }
    renderFeatures(plan, body);

    input.addEventListener('change', () => {
      state.selectedPlanId = plan.id;
      clearFeedback(elements);
      elements.payload.hidden = true;
      elements.payload.textContent = '';
      renderPlans(elements);
    });

    label.append(input, body);
    return label;
  }

  function renderPlans(elements) {
    elements.plans.textContent = '';

    for (const plan of state.plans) {
      elements.plans.append(createPlanOption(plan, elements));
    }

    updateSummary(elements);
    elements.submit.disabled = state.loading || state.plans.length === 0;
  }

  function getPaymentMethod() {
    const selected = document.querySelector('[data-payment-method]:checked');
    return selected?.value || '';
  }

  async function loadPlans(elements, requestedPlan) {
    setLoading(elements, true);
    elements.payload.hidden = true;
    elements.payload.textContent = '';
    clearFeedback(elements);

    try {
      const plans = await loadPublicCheckoutPlans({
        config: window.SIXAPP_PUBLIC_CONFIG,
        language: state.language,
      });
      const selection = resolveSelectedCheckoutPlan(
        plans,
        state.selectedPlanId || requestedPlan,
      );

      state.plans = plans;
      state.selectedPlanId = selection.plan?.id || '';
      renderPlans(elements);

      if (selection.fallbackReason === 'invalid' ||
          hasUnsafeCheckoutPriceParam(window.location.search)) {
        setFeedback(elements, 'error.invalidPlan', false);
      }
    } catch (error) {
      state.plans = [];
      state.selectedPlanId = '';
      renderPlans(elements);
      setFeedback(elements, checkoutErrorKeyFromError(error), false);
    } finally {
      setLoading(elements, false);
    }
  }

  function handleSubmit(elements, event) {
    event.preventDefault();

    if (state.loading) {
      return;
    }

    try {
      const payload = buildCheckoutPayload({
        plan: getSelectedPlan(),
        paymentMethod: validateCheckoutPaymentMethod(getPaymentMethod()),
      });
      elements.payload.hidden = false;
      elements.payload.textContent = JSON.stringify(payload, null, 2);
      setFeedback(elements, 'success.simulated', false);
      elements.payload.focus({ preventScroll: false });
    } catch (error) {
      elements.payload.hidden = true;
      elements.payload.textContent = '';
      setFeedback(elements, checkoutErrorKeyFromError(error), true);
    }
  }

  function initialize() {
    const elements = collectElements();
    if (!hasRequiredElements(elements)) return;

    document.documentElement.classList.add('has-js');
    state.language = applyPublicLanguage({
      dictionary: CHECKOUT_DICTIONARY,
      language: selectPublicLanguage(),
    });
    state.selectedPlanId = getCheckoutPlanFromSearch(window.location.search);

    setupPublicLanguageSwitcher({
      dictionary: CHECKOUT_DICTIONARY,
      onChange: (language) => {
        state.language = language;
        if (state.feedbackKey) {
          elements.feedback.textContent = copy(state.feedbackKey);
        }
        loadPlans(elements, state.selectedPlanId);
      },
    });

    elements.form.addEventListener('submit', (event) => {
      handleSubmit(elements, event);
    });

    document.querySelectorAll('[data-payment-method]').forEach((input) => {
      input.addEventListener('change', () => {
        clearFeedback(elements);
        elements.payload.hidden = true;
        elements.payload.textContent = '';
      });
    });

    loadPlans(elements, state.selectedPlanId);
    cleanupLegacyFlutterWorker();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initialize);
  } else {
    initialize();
  }
})();
