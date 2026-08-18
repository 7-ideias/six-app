import {
  applyPublicLanguage,
  cleanupLegacyFlutterWorker,
  selectPublicLanguage,
  setupPublicLanguageSwitcher,
} from './public-locale.mjs';
import {
  CATALOG_DICTIONARY,
  buildCatalogReservationPayload,
  calculateCatalogSelection,
  catalogErrorKey,
  fetchPublicCatalog,
  formatCatalogMoney,
  getCatalogTokenFromSearch,
  setCatalogSelectionQuantity,
  submitCatalogReservation,
} from './catalog-core.mjs';

(function () {
  'use strict';

  const state = {
    language: 'pt',
    token: '',
    catalog: null,
    selection: {},
    search: '',
    loading: true,
    submitting: false,
    idempotencyKey: '',
    feedbackKey: '',
    successProtocol: '',
  };

  function copy(key, variables = {}) {
    let value = CATALOG_DICTIONARY[state.language]?.[key] ||
      CATALOG_DICTIONARY.pt[key] || key;
    for (const [name, replacement] of Object.entries(variables)) {
      value = value.replaceAll(`{${name}}`, String(replacement));
    }
    return value;
  }

  function collectElements() {
    return {
      content: document.querySelector('[data-catalog-workspace]'),
      main: document.querySelector('#catalog-content'),
      loading: document.querySelector('[data-catalog-loading]'),
      error: document.querySelector('[data-catalog-error]'),
      companySection: document.querySelector('[data-company-section]'),
      companyName: document.querySelector('[data-company-name]'),
      companyTitle: document.querySelector('[data-company-title]'),
      companyAddress: document.querySelector('[data-company-address]'),
      companyContact: document.querySelector('[data-company-contact]'),
      companyContactLinks: document.querySelector('[data-company-contact-links]'),
      companyLogo: document.querySelector('[data-company-logo]'),
      companyLogoLarge: document.querySelector('[data-company-logo-large]'),
      productsGrid: document.querySelector('[data-products-grid]'),
      productsEmpty: document.querySelector('[data-products-empty]'),
      productsCount: document.querySelector('[data-products-count]'),
      search: document.querySelector('[data-catalog-search]'),
      selectionList: document.querySelector('[data-selection-list]'),
      selectionEmpty: document.querySelector('[data-selection-empty]'),
      selectionSummary: document.querySelector('[data-selection-summary]'),
      selectionTotal: document.querySelector('[data-selection-total]'),
      selectionCount: document.querySelector('[data-selection-count]'),
      selectionBadge: document.querySelector('[data-selection-badge]'),
      form: document.querySelector('[data-reservation-form]'),
      feedback: document.querySelector('[data-reservation-feedback]'),
      submit: document.querySelector('[data-reservation-submit]'),
      submitLabel: document.querySelector('[data-reservation-submit-label]'),
    };
  }

  function setCatalogError(elements, key) {
    elements.error.hidden = false;
    elements.error.textContent = copy(key);
    elements.error.focus({ preventScroll: false });
  }

  function setReservationFeedback(elements, key, { success = false, focus = false } = {}) {
    state.feedbackKey = key;
    elements.feedback.hidden = false;
    elements.feedback.classList.toggle('is-success', success);
    elements.feedback.textContent = key === 'success.body'
      ? copy(key, { protocol: state.successProtocol })
      : copy(key);
    if (focus) elements.feedback.focus({ preventScroll: false });
  }

  function clearReservationFeedback(elements) {
    state.feedbackKey = '';
    state.successProtocol = '';
    elements.feedback.hidden = true;
    elements.feedback.textContent = '';
    elements.feedback.classList.remove('is-success');
  }

  function toImageSource(value) {
    const normalized = String(value || '').trim();
    if (!normalized) return '';
    return normalized.startsWith('data:') ? normalized : `data:image/jpeg;base64,${normalized}`;
  }

  function safeExternalUrl(value) {
    try {
      const url = new URL(value);
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

  function renderCompany(elements) {
    const company = state.catalog.company;
    const companyName = company.name || company.legalName || copy('title');
    elements.companyName.textContent = companyName;
    elements.companyTitle.textContent = companyName;
    document.title = `${companyName} • ${copy('title')}`;

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
    elements.companyContact.hidden = elements.companyContactLinks.childElementCount === 0;

    const logoSource = toImageSource(company.logoBase64);
    if (logoSource) {
      elements.companyLogo.src = logoSource;
      elements.companyLogoLarge.src = logoSource;
    }
    elements.companySection.hidden = false;
  }

  function createProductImage(product) {
    const wrapper = document.createElement('div');
    wrapper.className = 'product-image';
    const source = product.imageUrl || toImageSource(product.imageBase64);
    if (source) {
      const image = document.createElement('img');
      image.src = source;
      image.alt = product.name;
      image.loading = 'lazy';
      image.decoding = 'async';
      wrapper.append(image);
    } else {
      const placeholder = document.createElement('span');
      placeholder.className = 'product-placeholder';
      placeholder.textContent = '◇';
      placeholder.setAttribute('aria-hidden', 'true');
      wrapper.append(placeholder);
    }
    return wrapper;
  }

  function createProductCard(product, elements) {
    const selected = Boolean(state.selection[product.id]);
    const card = document.createElement('article');
    card.className = `product-card${selected ? ' is-selected' : ''}`;
    card.append(createProductImage(product));

    const body = document.createElement('div');
    body.className = 'product-body';
    const title = document.createElement('h3');
    title.textContent = product.name;
    const model = document.createElement('p');
    model.className = 'product-model';
    model.textContent = product.model
      ? `${copy('product.model')}: ${product.model}`
      : '\u00a0';
    const price = document.createElement('span');
    price.className = 'product-price';
    price.textContent = formatCatalogMoney(
      product.price,
      state.catalog.currencyCode,
      state.catalog.locale,
    );

    const button = document.createElement('button');
    button.type = 'button';
    button.className = `button button-quiet product-action${selected ? ' is-selected' : ''}`;
    button.textContent = selected ? copy('product.chosen') : copy('product.choose');
    button.setAttribute('aria-pressed', selected ? 'true' : 'false');
    button.addEventListener('click', () => {
      state.selection = setCatalogSelectionQuantity(
        state.selection,
        product.id,
        selected ? 0 : 1,
      );
      clearReservationFeedback(elements);
      renderCatalog(elements);
    });

    body.append(title, model, price, button);
    card.append(body);
    return card;
  }

  function filteredProducts() {
    const term = state.search.trim().toLocaleLowerCase(state.catalog.locale);
    if (!term) return state.catalog.products;
    return state.catalog.products.filter((product) =>
      `${product.name} ${product.model}`.toLocaleLowerCase(state.catalog.locale).includes(term));
  }

  function renderProducts(elements) {
    const products = filteredProducts();
    elements.productsGrid.textContent = '';
    elements.productsCount.textContent = copy('catalog.itemsCount', {
      count: state.catalog.products.length,
    });

    for (const product of products) {
      elements.productsGrid.append(createProductCard(product, elements));
    }

    elements.productsEmpty.hidden = products.length > 0;
    elements.productsEmpty.textContent = state.catalog.products.length
      ? copy('catalog.noResults')
      : copy('catalog.empty');
  }

  function quantityButton(label, onClick, ariaLabel) {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'quantity-button';
    button.textContent = label;
    button.setAttribute('aria-label', ariaLabel);
    button.addEventListener('click', onClick);
    return button;
  }

  function renderSelection(elements) {
    const summary = calculateCatalogSelection(state.catalog, state.selection);
    elements.selectionList.textContent = '';
    elements.selectionEmpty.hidden = summary.items.length > 0;
    elements.selectionSummary.hidden = summary.items.length === 0;
    elements.selectionCount.textContent = copy('catalog.itemsCount', { count: summary.quantity });
    elements.selectionBadge.textContent = String(summary.quantity);
    elements.selectionTotal.textContent = formatCatalogMoney(
      summary.total,
      state.catalog.currencyCode,
      state.catalog.locale,
    );

    for (const item of summary.items) {
      const row = document.createElement('div');
      row.className = 'selection-row';
      const itemCopy = document.createElement('div');
      itemCopy.className = 'selection-row-copy';
      const name = document.createElement('strong');
      name.textContent = item.product.name;
      const price = document.createElement('small');
      price.textContent = formatCatalogMoney(
        item.product.price * item.quantity,
        state.catalog.currencyCode,
        state.catalog.locale,
      );
      itemCopy.append(name, price);

      const actions = document.createElement('div');
      actions.className = 'selection-row-actions';
      actions.append(quantityButton('−', () => {
        state.selection = setCatalogSelectionQuantity(
          state.selection,
          item.product.id,
          item.quantity - 1,
        );
        clearReservationFeedback(elements);
        renderCatalog(elements);
      }, `${copy('selection.quantity')} -`));
      const quantity = document.createElement('strong');
      quantity.textContent = String(item.quantity);
      actions.append(quantity);
      actions.append(quantityButton('+', () => {
        state.selection = setCatalogSelectionQuantity(
          state.selection,
          item.product.id,
          item.quantity + 1,
        );
        clearReservationFeedback(elements);
        renderCatalog(elements);
      }, `${copy('selection.quantity')} +`));

      row.append(itemCopy, actions);
      elements.selectionList.append(row);
    }

    elements.submit.disabled = state.submitting || summary.items.length === 0;
    elements.submitLabel.textContent = state.submitting
      ? copy('form.sending')
      : copy('form.submit');
  }

  function renderCatalog(elements) {
    if (!state.catalog) return;
    renderCompany(elements);
    renderProducts(elements);
    renderSelection(elements);
    if (state.feedbackKey) {
      setReservationFeedback(elements, state.feedbackKey, {
        success: state.feedbackKey === 'success.body',
      });
    }
  }

  function generateIdempotencyKey() {
    if (globalThis.crypto?.randomUUID) return globalThis.crypto.randomUUID();
    return `catalog-${Date.now()}-${Math.random().toString(36).slice(2, 12)}`;
  }

  async function loadCatalog(elements) {
    state.loading = true;
    elements.main.setAttribute('aria-busy', 'true');
    elements.loading.hidden = false;
    elements.error.hidden = true;
    elements.content.hidden = true;

    try {
      state.token = getCatalogTokenFromSearch(window.location.search);
      state.catalog = await fetchPublicCatalog({
        config: window.SIXAPP_PUBLIC_CONFIG,
        token: state.token,
      });
      elements.content.hidden = false;
      renderCatalog(elements);
    } catch (error) {
      state.catalog = null;
      setCatalogError(elements, catalogErrorKey(error));
    } finally {
      state.loading = false;
      elements.loading.hidden = true;
      elements.main.setAttribute('aria-busy', 'false');
    }
  }

  async function submitReservation(elements, event) {
    event.preventDefault();
    if (!state.catalog || state.submitting) return;

    const formData = new FormData(elements.form);
    try {
      state.idempotencyKey ||= generateIdempotencyKey();
      const payload = buildCatalogReservationPayload({
        idempotencyKey: state.idempotencyKey,
        name: formData.get('name'),
        phone: formData.get('phone'),
        email: formData.get('email'),
        notes: formData.get('notes'),
        selection: state.selection,
      });

      state.submitting = true;
      clearReservationFeedback(elements);
      renderSelection(elements);
      const response = await submitCatalogReservation({
        config: window.SIXAPP_PUBLIC_CONFIG,
        token: state.token,
        payload,
      });

      state.successProtocol = String(response?.idReserva || '').slice(0, 12) || '-';
      state.feedbackKey = 'success.body';
      state.selection = {};
      state.idempotencyKey = '';
      elements.form.reset();
      renderCatalog(elements);
      setReservationFeedback(elements, 'success.body', { success: true, focus: true });
    } catch (error) {
      setReservationFeedback(elements, catalogErrorKey(error), { focus: true });
    } finally {
      state.submitting = false;
      renderSelection(elements);
    }
  }

  function initialize() {
    const elements = collectElements();
    if (!elements.main || !elements.content || !elements.form || !elements.productsGrid) return;

    document.documentElement.classList.add('has-js');
    state.language = applyPublicLanguage({
      dictionary: CATALOG_DICTIONARY,
      language: selectPublicLanguage(),
    });

    setupPublicLanguageSwitcher({
      dictionary: CATALOG_DICTIONARY,
      onChange: (language) => {
        state.language = language;
        renderCatalog(elements);
      },
    });

    elements.search.addEventListener('input', () => {
      state.search = elements.search.value;
      renderProducts(elements);
    });
    elements.form.addEventListener('submit', (event) => {
      submitReservation(elements, event);
    });

    loadCatalog(elements);
    cleanupLegacyFlutterWorker();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initialize);
  } else {
    initialize();
  }
})();
