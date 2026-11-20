import { applyPublicLanguage, selectPublicLanguage } from './public-locale.mjs';
import { shouldBlockPublicLoginOnMobile } from './login-core.mjs';

const copy = {
  pt: {
    title: 'Agenda Financeira · SixoApp',
    heading: 'Agenda Financeira',
    description: 'Abra sua agenda no aplicativo. Você também pode acessá-la pelo computador.',
    open: 'Abrir no SixoApp',
    web: 'Acessar pelo navegador',
  },
  en: {
    title: 'Financial agenda · SixoApp',
    heading: 'Financial agenda',
    description: 'Open your agenda in the app. You can also access it on your computer.',
    open: 'Open in SixoApp',
    web: 'Continue in browser',
  },
  es: {
    title: 'Agenda financiera · SixoApp',
    heading: 'Agenda financiera',
    description: 'Abre tu agenda en la aplicación. También puedes acceder desde tu computadora.',
    open: 'Abrir en SixoApp',
    web: 'Continuar en el navegador',
  },
};

const tablet = /iPad|Android/i.test(navigator.userAgent) ||
  (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
if (tablet || shouldBlockPublicLoginOnMobile(window)) {
  const language = new URLSearchParams(location.search).get('lang');
  applyPublicLanguage({
    dictionary: copy,
    language: Object.hasOwn(copy, language) ? language : selectPublicLanguage(),
    persist: false,
  });
} else {
  location.replace('/app/agenda-financeira');
}
