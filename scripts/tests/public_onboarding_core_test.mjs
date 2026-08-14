import assert from 'node:assert/strict';
import test from 'node:test';

import {
  ONBOARDING_DICTIONARY,
  ONBOARDING_STORAGE_KEY,
  ONBOARDING_SUCCESS_PATH,
  PublicOnboardingStorageError,
  PublicOnboardingValidationError,
  buildOnboardingProfile,
  createDefaultOnboardingSelections,
  getCompanyFromSearch,
  getOnboardingOptions,
  navigateToOnboardingSuccess,
  persistOnboardingProfile,
  translateSelectionsToLanguage,
} from '../../web/site-assets/js/onboarding-core.mjs';
import {
  assertPublicDictionaryParity,
} from '../../web/site-assets/js/public-locale.mjs';

class MemoryStorage {
  constructor() {
    this.calls = [];
    this.values = new Map();
  }

  setItem(key, value) {
    this.calls.push([key, value]);
    this.values.set(key, value);
  }

  getItem(key) {
    return this.values.get(key) || null;
  }
}

test('opcoes validas preservam labels do fluxo Flutter em pt', () => {
  assert.deepEqual(getOnboardingOptions('pt', 'businessModel'), [
    'Vendas de balcao',
    'Catalogo digital de vendas',
    'Vestuario',
    'Alimentacao',
    'Ordens de servico',
    'Operacao hibrida',
  ]);
  assert.deepEqual(getOnboardingOptions('pt', 'modules'), [
    'PDV e vendas',
    'Orcamentos',
    'Ordens de servico',
    'Estoque e compras',
    'Financeiro',
    'CRM e pos-venda',
  ]);
});

test('defaults mantem selecao obrigatoria inicial', () => {
  assert.deepEqual(createDefaultOnboardingSelections('pt'), {
    businessModel: ['Vendas de balcao'],
    segments: [],
    channels: [],
    modules: ['PDV e vendas'],
    aiFocus: [],
  });
});

test('build cria payload no contrato atual', () => {
  const profile = buildOnboardingProfile({
    businessName: '  Loja Central  ',
    teamSize: 12,
    language: 'pt',
    selections: {
      businessModel: ['Vendas de balcao'],
      segments: ['Assistencia tecnica'],
      channels: ['WhatsApp'],
      modules: ['PDV e vendas', 'Financeiro'],
      aiFocus: ['Relatorios executivos automaticos'],
    },
    now: () => new Date('2026-08-13T12:00:00.000Z'),
  });

  assert.deepEqual(profile, {
    businessName: 'Loja Central',
    teamSize: 12,
    businessModel: ['Vendas de balcao'],
    segments: ['Assistencia tecnica'],
    channels: ['WhatsApp'],
    modules: ['PDV e vendas', 'Financeiro'],
    aiFocus: ['Relatorios executivos automaticos'],
    createdAt: '2026-08-13T12:00:00.000Z',
  });
});

test('opcao obrigatoria vazia gera erro tipado', () => {
  assert.throws(
    () => buildOnboardingProfile({
      selections: {
        businessModel: [],
        segments: [],
        channels: [],
        modules: ['PDV e vendas'],
        aiFocus: [],
      },
    }),
    (error) => error instanceof PublicOnboardingValidationError &&
      error.code === 'required',
  );
});

test('dados invalidos de opcao e equipe sao rejeitados', () => {
  assert.throws(
    () => buildOnboardingProfile({
      teamSize: 0,
      selections: createDefaultOnboardingSelections('pt'),
    }),
    (error) => error instanceof PublicOnboardingValidationError &&
      error.code === 'invalidTeamSize',
  );

  assert.throws(
    () => buildOnboardingProfile({
      selections: {
        businessModel: ['Segmento inventado'],
        segments: [],
        channels: [],
        modules: ['PDV e vendas'],
        aiFocus: [],
      },
    }),
    (error) => error instanceof PublicOnboardingValidationError &&
      error.code === 'invalidOption',
  );
});

test('persistencia usa somente a chave publica atual', () => {
  const storage = new MemoryStorage();
  const profile = buildOnboardingProfile({
    selections: createDefaultOnboardingSelections('pt'),
    now: () => new Date('2026-08-13T12:00:00.000Z'),
  });

  persistOnboardingProfile({ profile, storage });

  assert.equal(storage.calls.length, 1);
  assert.equal(storage.calls[0][0], ONBOARDING_STORAGE_KEY);
  assert.deepEqual(JSON.parse(storage.getItem(ONBOARDING_STORAGE_KEY)), profile);
});

test('persistencia sem storage disponivel falha sem criar fallback sensivel', () => {
  assert.throws(
    () => persistOnboardingProfile({
      profile: {},
      storage: null,
    }),
    PublicOnboardingStorageError,
  );
});

test('destino final preserva login com source trial', () => {
  const calls = [];
  const result = navigateToOnboardingSuccess({
    replace(path) {
      calls.push(path);
    },
  });

  assert.equal(result, ONBOARDING_SUCCESS_PATH);
  assert.deepEqual(calls, ['/login?source=trial']);
});

test('company da query preenche nome opcional com trim', () => {
  assert.equal(
    getCompanyFromSearch('?company=%20Oficina%20Central%20'),
    'Oficina Central',
  );
});

test('locale parity cobre pt en es', () => {
  assert.equal(assertPublicDictionaryParity(ONBOARDING_DICTIONARY), true);
  assert.equal(getOnboardingOptions('en-US', 'channels')[0], 'Physical store');
  assert.equal(getOnboardingOptions('es-ES', 'channels')[0], 'Tienda fisica');
});

test('troca de idioma preserva selecoes por indice', () => {
  assert.deepEqual(
    translateSelectionsToLanguage({
      fromLanguage: 'pt',
      toLanguage: 'en',
      selections: {
        businessModel: ['Operacao hibrida'],
        segments: ['Eletronicos'],
        channels: ['Marketplace'],
        modules: ['Financeiro'],
        aiFocus: ['Previsao de demanda e caixa'],
      },
    }),
    {
      businessModel: ['Hybrid operation'],
      segments: ['Electronics'],
      channels: ['Marketplace'],
      modules: ['Finance'],
      aiFocus: ['Demand and cash forecast'],
    },
  );
});

test('nenhuma chave sensivel e usada na persistencia publica', () => {
  const storage = new MemoryStorage();
  const profile = buildOnboardingProfile({
    selections: createDefaultOnboardingSelections('pt'),
    now: () => new Date('2026-08-13T12:00:00.000Z'),
  });

  persistOnboardingProfile({ profile, storage });

  const sensitiveKeys = [
    'accessToken',
    'refreshToken',
    'usuario',
    'empresa',
    'permissoes',
    'preferencias',
  ];
  const persistedKeys = storage.calls.map(([key]) => key);
  for (const key of sensitiveKeys) {
    assert.equal(persistedKeys.includes(key), false);
  }
});
