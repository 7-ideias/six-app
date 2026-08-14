import {
  applyPublicLanguage,
  cleanupLegacyFlutterWorker,
  selectPublicLanguage,
  setupPublicLanguageSwitcher,
} from './public-locale.mjs';
import {
  ONBOARDING_DEFAULT_TEAM_SIZE,
  ONBOARDING_DICTIONARY,
  ONBOARDING_GROUP_KEYS,
  ONBOARDING_REQUIRED_GROUP_KEYS,
  buildOnboardingProfile,
  createDefaultOnboardingSelections,
  getCompanyFromSearch,
  getOnboardingOptions,
  navigateToOnboardingSuccess,
  onboardingErrorKeyFromError,
  persistOnboardingProfile,
  translateSelectionsToLanguage,
} from './onboarding-core.mjs';

(function () {
  'use strict';

  const state = {
    language: 'pt',
    selections: createDefaultOnboardingSelections('pt'),
    feedbackKey: null,
  };

  function copy(key) {
    return ONBOARDING_DICTIONARY[state.language]?.[key] ||
      ONBOARDING_DICTIONARY.pt[key] ||
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

  function updateTeamOutput(elements) {
    elements.teamSizeOutput.textContent = copy('team.output').replace(
      '{value}',
      elements.teamSize.value,
    );
  }

  function keepRequiredSelection(elements, groupKey, input) {
    if (!ONBOARDING_REQUIRED_GROUP_KEYS.includes(groupKey)) return false;
    if (state.selections[groupKey].length > 1) return false;
    input.checked = true;
    setFeedback(elements, 'error.required', false);
    return true;
  }

  function renderOptions(elements) {
    for (const groupKey of ONBOARDING_GROUP_KEYS) {
      const container = elements.optionGroups[groupKey];
      if (!container) continue;

      container.textContent = '';
      for (const option of getOnboardingOptions(state.language, groupKey)) {
        const label = document.createElement('label');
        label.className = 'choice-option';

        const input = document.createElement('input');
        input.type = 'checkbox';
        input.name = groupKey;
        input.value = option;
        input.checked = state.selections[groupKey]?.includes(option) || false;

        const text = document.createElement('span');
        text.textContent = option;

        input.addEventListener('change', () => {
          if (input.checked) {
            if (!state.selections[groupKey].includes(option)) {
              state.selections[groupKey].push(option);
            }
            clearFeedback(elements);
            return;
          }

          if (keepRequiredSelection(elements, groupKey, input)) {
            return;
          }

          state.selections[groupKey] = state.selections[groupKey].filter(
            (value) => value !== option,
          );
          clearFeedback(elements);
        });

        label.append(input, text);
        container.append(label);
      }
    }
  }

  function collectOptionGroups() {
    const groups = {};
    document.querySelectorAll('[data-onboarding-options]').forEach((node) => {
      groups[node.getAttribute('data-onboarding-options')] = node;
    });
    return groups;
  }

  function collectElements() {
    return {
      form: document.querySelector('[data-onboarding-form]'),
      businessName: document.querySelector('[data-business-name]'),
      teamSize: document.querySelector('[data-team-size]'),
      teamSizeOutput: document.querySelector('[data-team-size-output]'),
      feedback: document.querySelector('[data-onboarding-feedback]'),
      optionGroups: collectOptionGroups(),
    };
  }

  function hasRequiredElements(elements) {
    return Boolean(
      elements.form &&
      elements.businessName &&
      elements.teamSize &&
      elements.teamSizeOutput &&
      elements.feedback &&
      ONBOARDING_GROUP_KEYS.every((key) => Boolean(elements.optionGroups[key])),
    );
  }

  function handleSubmit(elements, event) {
    event.preventDefault();
    clearFeedback(elements);

    try {
      const profile = buildOnboardingProfile({
        businessName: elements.businessName.value,
        teamSize: elements.teamSize.valueAsNumber,
        selections: state.selections,
        language: state.language,
      });
      persistOnboardingProfile({ profile });
      setFeedback(elements, 'saved', false);
      window.setTimeout(() => {
        navigateToOnboardingSuccess(window.location);
      }, 120);
    } catch (error) {
      setFeedback(elements, onboardingErrorKeyFromError(error), true);
    }
  }

  function initialize() {
    const elements = collectElements();
    if (!hasRequiredElements(elements)) return;

    document.documentElement.classList.add('has-js');
    state.language = applyPublicLanguage({
      dictionary: ONBOARDING_DICTIONARY,
      language: selectPublicLanguage(),
    });
    state.selections = createDefaultOnboardingSelections(state.language);

    elements.businessName.value = getCompanyFromSearch(window.location.search);
    elements.teamSize.value = String(ONBOARDING_DEFAULT_TEAM_SIZE);
    renderOptions(elements);
    updateTeamOutput(elements);

    setupPublicLanguageSwitcher({
      dictionary: ONBOARDING_DICTIONARY,
      onChange: (language) => {
        const previousLanguage = state.language;
        state.language = language;
        state.selections = translateSelectionsToLanguage({
          selections: state.selections,
          fromLanguage: previousLanguage,
          toLanguage: language,
        });
        renderOptions(elements);
        updateTeamOutput(elements);
        if (state.feedbackKey) {
          elements.feedback.textContent = copy(state.feedbackKey);
        }
      },
    });

    elements.teamSize.addEventListener('input', () => {
      updateTeamOutput(elements);
    });

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
