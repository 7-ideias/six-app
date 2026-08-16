import { loadPublicCheckoutPlans } from './checkout-core.mjs';

const copy = Object.freeze({
  pt: Object.freeze({
    loading: 'Carregando planos publicados...',
    empty: 'Nenhum plano está publicado no momento.',
    error: 'Não foi possível carregar os planos agora.',
    retry: 'Tentar novamente',
    popular: 'Popular',
    trial: (days) => `${days} dias de teste`,
    users: (count) => `Até ${count} usuários`,
    unlimited: 'Usuários ilimitados',
    loyalty: (months) => `${months} meses de fidelidade`,
    cancelAnytime: 'Cancele quando quiser',
  }),
  en: Object.freeze({
    loading: 'Loading published plans...',
    empty: 'No plan is currently published.',
    error: 'Plans could not be loaded right now.',
    retry: 'Try again',
    popular: 'Popular',
    trial: (days) => `${days}-day trial`,
    users: (count) => `Up to ${count} users`,
    unlimited: 'Unlimited users',
    loyalty: (months) => `${months}-month commitment`,
    cancelAnytime: 'Cancel anytime',
  }),
  es: Object.freeze({
    loading: 'Cargando planes publicados...',
    empty: 'No hay ningún plan publicado actualmente.',
    error: 'No fue posible cargar los planes ahora.',
    retry: 'Intentar de nuevo',
    popular: 'Popular',
    trial: (days) => `${days} días de prueba`,
    users: (count) => `Hasta ${count} usuarios`,
    unlimited: 'Usuarios ilimitados',
    loyalty: (months) => `${months} meses de permanencia`,
    cancelAnytime: 'Cancela cuando quieras',
  }),
});

const container = document.querySelector('[data-public-plans]');
const status = document.querySelector('[data-public-plans-status]');
const retry = document.querySelector('[data-public-plans-retry]');
let requestId = 0;

function languageFromDocument() {
  const language = String(document.documentElement.lang || 'pt').toLowerCase();
  if (language.startsWith('en')) return 'en';
  if (language.startsWith('es')) return 'es';
  return 'pt';
}

function appendText(parent, tagName, className, text) {
  const element = document.createElement(tagName);
  if (className) element.className = className;
  element.textContent = text;
  parent.appendChild(element);
  return element;
}

function conditionLabels(plan, language) {
  const labels = [];
  const conditions = plan.conditions || {};
  if (conditions.trialDays > 0) labels.push(copy[language].trial(conditions.trialDays));
  if (Number.isInteger(conditions.userLimit) && conditions.userLimit > 0) {
    labels.push(copy[language].users(conditions.userLimit));
  } else if (conditions.userLimit === null) {
    labels.push(copy[language].unlimited);
  }
  if (conditions.loyaltyMonths > 0) {
    labels.push(copy[language].loyalty(conditions.loyaltyMonths));
  }
  if (conditions.cancelAnytime) labels.push(copy[language].cancelAnytime);
  return labels;
}

function renderPlan(plan, index, language) {
  const card = document.createElement('article');
  card.className = `plan-path-card public-plan-card${plan.featured ? ' is-highlighted' : ''}`;

  appendText(card, 'span', 'plan-path-number', String(index + 1).padStart(2, '0'));
  if (plan.featured) appendText(card, 'span', 'public-plan-badge', copy[language].popular);
  appendText(card, 'h3', '', plan.name);
  appendText(card, 'p', 'public-plan-description', plan.pitch);

  const price = document.createElement('p');
  price.className = 'public-plan-price';
  appendText(price, 'strong', '', plan.price);
  appendText(price, 'span', '', plan.cadence);
  card.appendChild(price);

  const benefits = document.createElement('ul');
  benefits.className = 'public-plan-benefits';
  [...plan.features, ...conditionLabels(plan, language)].forEach((benefit) => {
    appendText(benefits, 'li', '', benefit);
  });
  card.appendChild(benefits);

  const action = appendText(
    card,
    'a',
    `button ${plan.featured ? 'button-light' : 'button-quiet'}`,
    plan.cta,
  );
  const query = new URLSearchParams({ plan: plan.id });
  action.href = `${plan.billingPeriod === 'GRATUITO' || plan.rawAmount === 0 ? '/register' : '/checkout'}?${query}`;
  return card;
}

function setStatus(message, { showRetry = false } = {}) {
  status.textContent = message;
  status.hidden = !message;
  retry.textContent = copy[languageFromDocument()].retry;
  retry.hidden = !showRetry;
}

async function loadPlans() {
  if (!container || !status || !retry) return;
  const currentRequest = ++requestId;
  const language = languageFromDocument();
  container.replaceChildren();
  container.setAttribute('aria-busy', 'true');
  setStatus(copy[language].loading);

  try {
    const plans = await loadPublicCheckoutPlans({
      config: window.SIXAPP_PUBLIC_CONFIG,
      language,
    });
    if (currentRequest !== requestId) return;
    if (plans.length === 0) {
      setStatus(copy[language].empty);
      return;
    }
    container.replaceChildren(
      ...plans.map((plan, index) => renderPlan(plan, index, language)),
    );
    setStatus('');
  } catch (_) {
    if (currentRequest !== requestId) return;
    setStatus(copy[language].error, { showRetry: true });
  } finally {
    if (currentRequest === requestId) container.setAttribute('aria-busy', 'false');
  }
}

retry?.addEventListener('click', loadPlans);
window.addEventListener('sixapp:locale-changed', loadPlans);
loadPlans();
