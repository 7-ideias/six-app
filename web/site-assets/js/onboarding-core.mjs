import { normalizePublicLanguage } from './public-locale.mjs';

export const ONBOARDING_STORAGE_KEY = 'web_trial_onboarding_profile';
export const ONBOARDING_SUCCESS_PATH = '/login?source=trial';
export const ONBOARDING_DEFAULT_TEAM_SIZE = 3;
export const ONBOARDING_MIN_TEAM_SIZE = 1;
export const ONBOARDING_MAX_TEAM_SIZE = 200;

export const ONBOARDING_GROUP_KEYS = Object.freeze([
  'businessModel',
  'segments',
  'channels',
  'modules',
  'aiFocus',
]);

export const ONBOARDING_REQUIRED_GROUP_KEYS = Object.freeze([
  'businessModel',
  'modules',
]);

export const ONBOARDING_DICTIONARY = Object.freeze({
  pt: Object.freeze({
    title: 'SixoApp - Onboarding',
    description: 'Informe o perfil do seu negócio para iniciar o teste guiado do SixoApp.',
    ogTitle: 'SixoApp - Onboarding',
    ogDescription: 'Onboarding público para preparar seu perfil de teste no SixoApp.',
    twitterTitle: 'SixoApp - Onboarding',
    twitterDescription: 'Escolha o perfil do seu negócio antes de entrar no SixoApp.',
    'access.skip': 'Ir para o formulário de onboarding',
    'brand.aria': 'SixoApp',
    'nav.home': 'Voltar para a página inicial',
    'language.aria': 'Selecionar idioma',
    'context.eyebrow': 'Teste guiado',
    'context.title': 'Conte um pouco sobre seu negócio',
    'context.body': 'Suas escolhas ficam salvas localmente para continuar pelo login.',
    'step.business': 'Como sua operação vende hoje?',
    'step.segments': 'Quais segmentos representam seu negócio?',
    'step.channels': 'Quais canais de venda você utiliza?',
    'step.modules': 'Quais módulos quer ativar no piloto?',
    'step.ai': 'Onde a IA deve priorizar ganhos?',
    'step.team': 'Quantas pessoas usam o sistema?',
    'field.businessName.label': 'Nome do negócio (opcional)',
    'field.businessName.placeholder': 'Informe o nome do negócio',
    'team.output': '{value} usuários estimados',
    'form.submit': 'Continuar',
    'footer.login.prompt': 'Já tem uma conta?',
    'footer.login.link': 'Entrar',
    'footer.compatibility': 'Usar versão compatível',
    'noscript.message': 'Para usar esta página, ative o JavaScript. Você também pode acessar a versão compatível.',
    'noscript.link': 'Usar versão compatível',
    saved: 'Perfil salvo. Continue no login para iniciar o teste.',
    'error.required': 'Mantenha ao menos uma opção nas perguntas obrigatórias.',
    'error.invalid': 'Revise as opções selecionadas e tente novamente.',
    'error.storage': 'Não foi possível salvar este perfil no navegador.',
  }),
  en: Object.freeze({
    title: 'SixoApp - Onboarding',
    description: 'Enter your business profile to start the guided SixoApp trial.',
    ogTitle: 'SixoApp - Onboarding',
    ogDescription: 'Public onboarding to prepare your SixoApp trial profile.',
    twitterTitle: 'SixoApp - Onboarding',
    twitterDescription: 'Choose your business profile before signing in to SixoApp.',
    'access.skip': 'Skip to the onboarding form',
    'brand.aria': 'SixoApp',
    'nav.home': 'Back to the home page',
    'language.aria': 'Select language',
    'context.eyebrow': 'Guided trial',
    'context.title': 'Tell us a little about your business',
    'context.body': 'Your choices are saved locally so you can continue through sign in.',
    'step.business': 'How does your operation sell today?',
    'step.segments': 'Which segments represent your business?',
    'step.channels': 'Which sales channels do you use?',
    'step.modules': 'Which modules do you want in the pilot?',
    'step.ai': 'Where should AI prioritize gains?',
    'step.team': 'How many users will access the system?',
    'field.businessName.label': 'Business name (optional)',
    'field.businessName.placeholder': 'Enter the business name',
    'team.output': '{value} estimated users',
    'form.submit': 'Continue',
    'footer.login.prompt': 'Already have an account?',
    'footer.login.link': 'Sign in',
    'footer.compatibility': 'Use compatible version',
    'noscript.message': 'Enable JavaScript to use this page. You can also access the compatible version.',
    'noscript.link': 'Use compatible version',
    saved: 'Profile saved. Continue through login to start your trial.',
    'error.required': 'Keep at least one option in the required questions.',
    'error.invalid': 'Review the selected options and try again.',
    'error.storage': 'Could not save this profile in the browser.',
  }),
  es: Object.freeze({
    title: 'SixoApp - Onboarding',
    description: 'Informa el perfil de tu negocio para iniciar la prueba guiada de SixoApp.',
    ogTitle: 'SixoApp - Onboarding',
    ogDescription: 'Onboarding público para preparar tu perfil de prueba en SixoApp.',
    twitterTitle: 'SixoApp - Onboarding',
    twitterDescription: 'Elige el perfil de tu negocio antes de entrar en SixoApp.',
    'access.skip': 'Ir al formulario de onboarding',
    'brand.aria': 'SixoApp',
    'nav.home': 'Volver a la página inicial',
    'language.aria': 'Seleccionar idioma',
    'context.eyebrow': 'Prueba guiada',
    'context.title': 'Cuenta un poco sobre tu negocio',
    'context.body': 'Tus elecciones se guardan localmente para continuar por el login.',
    'step.business': 'Como vende tu operacion hoy?',
    'step.segments': 'Que segmentos representan tu negocio?',
    'step.channels': 'Que canales de venta usas?',
    'step.modules': 'Que modulos quieres activar?',
    'step.ai': 'Donde la IA debe priorizar ganancias?',
    'step.team': 'Cuantas personas usaran el sistema?',
    'field.businessName.label': 'Nombre del negocio (opcional)',
    'field.businessName.placeholder': 'Informa el nombre del negocio',
    'team.output': '{value} usuarios estimados',
    'form.submit': 'Continuar',
    'footer.login.prompt': '¿Ya tienes una cuenta?',
    'footer.login.link': 'Entrar',
    'footer.compatibility': 'Usar versión compatible',
    'noscript.message': 'Para usar esta página, activa JavaScript. También puedes acceder a la versión compatible.',
    'noscript.link': 'Usar versión compatible',
    saved: 'Perfil guardado. Continua por login para iniciar la prueba.',
    'error.required': 'Mantén al menos una opción en las preguntas obligatorias.',
    'error.invalid': 'Revisa las opciones seleccionadas e intenta nuevamente.',
    'error.storage': 'No fue posible guardar este perfil en el navegador.',
  }),
});

const optionSets = {
  pt: {
    businessModel: [
      'Vendas de balcao',
      'Catalogo digital de vendas',
      'Vestuario',
      'Alimentacao',
      'Ordens de servico',
      'Operacao hibrida',
    ],
    segments: [
      'Moda',
      'Food service',
      'Eletronicos',
      'Autopecas',
      'Assistencia tecnica',
      'Casa e decoracao',
    ],
    channels: [
      'Loja fisica',
      'WhatsApp',
      'E-commerce proprio',
      'Marketplace',
      'Equipe externa',
    ],
    modules: [
      'PDV e vendas',
      'Orcamentos',
      'Ordens de servico',
      'Estoque e compras',
      'Financeiro',
      'CRM e pos-venda',
    ],
    aiFocus: [
      'Cadastro inteligente de produtos e clientes',
      'Sugestao de precificacao e margem',
      'Relatorios executivos automaticos',
      'Previsao de demanda e caixa',
      'Automacao de follow-up comercial',
    ],
  },
  en: {
    businessModel: [
      'Counter sales',
      'Digital sales catalog',
      'Fashion retail',
      'Food operation',
      'Service orders',
      'Hybrid operation',
    ],
    segments: [
      'Fashion',
      'Food service',
      'Electronics',
      'Auto parts',
      'Technical assistance',
      'Home and decor',
    ],
    channels: [
      'Physical store',
      'WhatsApp',
      'Own e-commerce',
      'Marketplace',
      'Field team',
    ],
    modules: [
      'POS and sales',
      'Quotations',
      'Service orders',
      'Inventory and purchasing',
      'Finance',
      'CRM and retention',
    ],
    aiFocus: [
      'Smart product and customer setup',
      'Pricing and margin suggestions',
      'Automatic executive reports',
      'Demand and cash forecast',
      'Sales follow-up automation',
    ],
  },
  es: {
    businessModel: [
      'Ventas de mostrador',
      'Catalogo digital de ventas',
      'Moda',
      'Alimentacion',
      'Ordenes de servicio',
      'Operacion hibrida',
    ],
    segments: [
      'Moda',
      'Food service',
      'Electronica',
      'Autopartes',
      'Asistencia tecnica',
      'Casa y decoracion',
    ],
    channels: [
      'Tienda fisica',
      'WhatsApp',
      'E-commerce propio',
      'Marketplace',
      'Equipo externo',
    ],
    modules: [
      'POS y ventas',
      'Presupuestos',
      'Ordenes de servicio',
      'Inventario y compras',
      'Finanzas',
      'CRM y postventa',
    ],
    aiFocus: [
      'Registro inteligente de productos y clientes',
      'Sugerencias de precios y margen',
      'Reportes ejecutivos automaticos',
      'Prevision de demanda y caja',
      'Automatizacion de seguimiento comercial',
    ],
  },
};

function freezeOptionSets(source) {
  return Object.freeze(Object.fromEntries(
    Object.entries(source).map(([language, groups]) => [
      language,
      Object.freeze(Object.fromEntries(
        Object.entries(groups).map(([group, values]) => [
          group,
          Object.freeze([...values]),
        ]),
      )),
    ]),
  ));
}

export const ONBOARDING_OPTIONS = freezeOptionSets(optionSets);

export class PublicOnboardingValidationError extends Error {
  constructor(code) {
    super(code);
    this.name = 'PublicOnboardingValidationError';
    this.code = code;
  }
}

export class PublicOnboardingStorageError extends Error {
  constructor() {
    super('Onboarding storage failure');
    this.name = 'PublicOnboardingStorageError';
  }
}

export function getOnboardingOptions(language, groupKey) {
  const normalized = normalizePublicLanguage(language);
  const group = ONBOARDING_OPTIONS[normalized]?.[groupKey] ||
    ONBOARDING_OPTIONS.pt[groupKey];
  if (!group) {
    throw new PublicOnboardingValidationError('invalidGroup');
  }
  return [...group];
}

export function createDefaultOnboardingSelections(language = 'pt') {
  const result = {};
  for (const groupKey of ONBOARDING_GROUP_KEYS) {
    result[groupKey] = [];
  }

  for (const groupKey of ONBOARDING_REQUIRED_GROUP_KEYS) {
    const options = getOnboardingOptions(language, groupKey);
    if (options.length > 0) {
      result[groupKey] = [options[0]];
    }
  }

  return result;
}

export function normalizeBusinessName(value) {
  return String(value || '').trim();
}

export function normalizeTeamSize(value) {
  const numeric = Number(value);
  if (!Number.isInteger(numeric) ||
    numeric < ONBOARDING_MIN_TEAM_SIZE ||
    numeric > ONBOARDING_MAX_TEAM_SIZE) {
    throw new PublicOnboardingValidationError('invalidTeamSize');
  }
  return numeric;
}

export function normalizeOnboardingSelections({
  selections,
  language = 'pt',
} = {}) {
  const normalizedSelections = {};

  for (const groupKey of ONBOARDING_GROUP_KEYS) {
    const options = getOnboardingOptions(language, groupKey);
    const allowed = new Set(options);
    const rawValues = Array.isArray(selections?.[groupKey])
      ? selections[groupKey]
      : [];
    const values = [];

    for (const rawValue of rawValues) {
      const value = String(rawValue || '').trim();
      if (!value) continue;
      if (!allowed.has(value)) {
        throw new PublicOnboardingValidationError('invalidOption');
      }
      if (!values.includes(value)) {
        values.push(value);
      }
    }

    if (ONBOARDING_REQUIRED_GROUP_KEYS.includes(groupKey) &&
      values.length === 0) {
      throw new PublicOnboardingValidationError('required');
    }

    normalizedSelections[groupKey] = Object.freeze(values);
  }

  return Object.freeze(normalizedSelections);
}

export function buildOnboardingProfile({
  businessName = '',
  teamSize = ONBOARDING_DEFAULT_TEAM_SIZE,
  selections,
  language = 'pt',
  now = () => new Date(),
} = {}) {
  const normalizedSelections = normalizeOnboardingSelections({
    selections,
    language,
  });
  const current = typeof now === 'function' ? now() : now;
  const createdAtDate = current instanceof Date ? current : new Date(current);

  if (Number.isNaN(createdAtDate.getTime())) {
    throw new PublicOnboardingValidationError('invalidDate');
  }

  return Object.freeze({
    businessName: normalizeBusinessName(businessName),
    teamSize: normalizeTeamSize(teamSize),
    businessModel: normalizedSelections.businessModel,
    segments: normalizedSelections.segments,
    channels: normalizedSelections.channels,
    modules: normalizedSelections.modules,
    aiFocus: normalizedSelections.aiFocus,
    createdAt: createdAtDate.toISOString(),
  });
}

export function persistOnboardingProfile({
  profile,
  storage = globalThis.localStorage,
} = {}) {
  if (!storage || typeof storage.setItem !== 'function') {
    throw new PublicOnboardingStorageError();
  }

  try {
    storage.setItem(ONBOARDING_STORAGE_KEY, JSON.stringify(profile));
    return profile;
  } catch (_) {
    throw new PublicOnboardingStorageError();
  }
}

export function getCompanyFromSearch(search = '') {
  const raw = String(search || '');
  const query = raw.startsWith('?') ? raw.slice(1) : raw;
  return normalizeBusinessName(new URLSearchParams(query).get('company'));
}

export function translateSelectionsToLanguage({
  selections,
  fromLanguage,
  toLanguage,
} = {}) {
  const translated = {};

  for (const groupKey of ONBOARDING_GROUP_KEYS) {
    const fromOptions = getOnboardingOptions(fromLanguage, groupKey);
    const toOptions = getOnboardingOptions(toLanguage, groupKey);
    const selected = Array.isArray(selections?.[groupKey])
      ? selections[groupKey]
      : [];
    translated[groupKey] = selected
      .map((value) => fromOptions.indexOf(value))
      .filter((index) => index >= 0 && index < toOptions.length)
      .map((index) => toOptions[index]);

    if (ONBOARDING_REQUIRED_GROUP_KEYS.includes(groupKey) &&
      translated[groupKey].length === 0 &&
      toOptions.length > 0) {
      translated[groupKey] = [toOptions[0]];
    }
  }

  return translated;
}

export function onboardingErrorKeyFromError(error) {
  if (error instanceof PublicOnboardingStorageError) {
    return 'error.storage';
  }
  if (error instanceof PublicOnboardingValidationError) {
    return error.code === 'required' ? 'error.required' : 'error.invalid';
  }
  return 'error.invalid';
}

export function navigateToOnboardingSuccess(
  locationRef = globalThis.location,
) {
  if (locationRef && typeof locationRef.replace === 'function') {
    locationRef.replace(ONBOARDING_SUCCESS_PATH);
    return ONBOARDING_SUCCESS_PATH;
  }
  if (locationRef && typeof locationRef.assign === 'function') {
    locationRef.assign(ONBOARDING_SUCCESS_PATH);
    return ONBOARDING_SUCCESS_PATH;
  }
  if (locationRef) {
    locationRef.href = ONBOARDING_SUCCESS_PATH;
  }
  return ONBOARDING_SUCCESS_PATH;
}
