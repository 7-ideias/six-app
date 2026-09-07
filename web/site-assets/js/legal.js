(function () {
  'use strict';

  var storageKey = 'sixapp.public.locale';
  var supported = ['pt', 'en', 'es'];

  var meta = {
    privacy: {
      pt: {
        lang: 'pt-BR',
        title: 'Política de Privacidade | SixoApp',
        description: 'Saiba como o SixoApp trata dados pessoais, dados comerciais, autenticação, integrações, segurança e direitos dos usuários.'
      },
      en: {
        lang: 'en',
        title: 'Privacy Policy | SixoApp',
        description: 'Learn how SixoApp processes personal data, business data, authentication, integrations, security, and user rights.'
      },
      es: {
        lang: 'es',
        title: 'Política de Privacidad | SixoApp',
        description: 'Conoce cómo SixoApp trata datos personales, datos comerciales, autenticación, integraciones, seguridad y derechos de los usuarios.'
      }
    },
    terms: {
      pt: {
        lang: 'pt-BR',
        title: 'Termos de Serviço | SixoApp',
        description: 'Termos aplicáveis ao uso do SixoApp, incluindo contas, permissões, planos, conteúdo, integrações, disponibilidade e responsabilidades.'
      },
      en: {
        lang: 'en',
        title: 'Terms of Service | SixoApp',
        description: 'Terms that apply to SixoApp use, including accounts, permissions, plans, content, integrations, availability, and responsibilities.'
      },
      es: {
        lang: 'es',
        title: 'Términos de Servicio | SixoApp',
        description: 'Términos aplicables al uso de SixoApp, incluidas cuentas, permisos, planes, contenido, integraciones, disponibilidad y responsabilidades.'
      }
    }
  };

  function normalize(value) {
    var code = String(value || '').trim().toLowerCase();
    if (code.indexOf('en') === 0) return 'en';
    if (code.indexOf('es') === 0) return 'es';
    return 'pt';
  }

  function storedLanguage() {
    try {
      return window.localStorage.getItem(storageKey);
    } catch (_) {
      return null;
    }
  }

  function browserLanguage() {
    var preferred = (navigator.languages && navigator.languages[0]) || navigator.language || 'pt-BR';
    return normalize(preferred);
  }

  function queryLanguage() {
    try {
      var value = new URL(window.location.href).searchParams.get('lang');
      return value ? normalize(value) : null;
    } catch (_) {
      return null;
    }
  }

  function persist(language) {
    try {
      window.localStorage.setItem(storageKey, language);
    } catch (_) {}
  }

  function updateQuery(language) {
    try {
      var url = new URL(window.location.href);
      if (language === 'pt') {
        url.searchParams.delete('lang');
      } else {
        url.searchParams.set('lang', language);
      }
      window.history.replaceState(null, '', url.pathname + url.search + url.hash);
    } catch (_) {}
  }

  function apply(language, userInitiated) {
    var normalized = normalize(language);
    var page = document.body.getAttribute('data-legal-page') || 'privacy';
    var pageMeta = (meta[page] && meta[page][normalized]) || meta.privacy.pt;

    document.documentElement.lang = pageMeta.lang;
    document.title = pageMeta.title;

    var description = document.querySelector('meta[name="description"]');
    if (description) description.setAttribute('content', pageMeta.description);

    var ogTitle = document.querySelector('meta[property="og:title"]');
    if (ogTitle) ogTitle.setAttribute('content', pageMeta.title);

    var ogDescription = document.querySelector('meta[property="og:description"]');
    if (ogDescription) ogDescription.setAttribute('content', pageMeta.description);

    document.querySelectorAll('[data-legal-lang]').forEach(function (node) {
      node.hidden = node.getAttribute('data-legal-lang') !== normalized;
    });

    document.querySelectorAll('[data-lang-option]').forEach(function (button) {
      button.setAttribute('aria-pressed', button.getAttribute('data-lang-option') === normalized ? 'true' : 'false');
    });

    document.querySelectorAll('[data-current-year]').forEach(function (node) {
      node.textContent = String(new Date().getFullYear());
    });

    persist(normalized);
    if (userInitiated) updateQuery(normalized);
  }

  document.querySelectorAll('[data-lang-option]').forEach(function (button) {
    button.addEventListener('click', function () {
      apply(button.getAttribute('data-lang-option'), true);
    });
  });

  var initial = queryLanguage() || storedLanguage() || browserLanguage();
  apply(initial, false);

  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations().then(function (registrations) {
      registrations.forEach(function (registration) {
        var worker = registration.active || registration.waiting || registration.installing;
        if (worker && worker.scriptURL && worker.scriptURL.indexOf('/flutter_service_worker.js') !== -1) {
          registration.unregister().catch(function () {});
        }
      });
    }).catch(function () {});
  }
})();
