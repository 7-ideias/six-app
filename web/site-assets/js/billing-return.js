(() => {
  'use strict';
  const params = new URLSearchParams(location.search);
  const locale = (params.get('locale') || navigator.language || 'pt').slice(0, 2);
  const translations = {
    pt: ['Continue no aplicativo SIX', 'Volte ao aplicativo para confirmar o status da sua assinatura.',
      'Voltar para o aplicativo SIX', 'Se o aplicativo não abrir, abra o SIX no celular e acesse sua assinatura. Não é necessário pagar novamente.',
      'Você voltou do checkout. Confira sua assinatura no aplicativo.', 'Retorno inválido. Abra o SIX e acesse sua assinatura.'],
    en: ['Continue in the SIX app', 'Return to the app to confirm your subscription status.',
      'Return to the SIX app', 'If the app does not open, open SIX on your phone and view your subscription. You do not need to pay again.',
      'You returned from checkout. Check your subscription in the app.', 'Invalid return link. Open SIX and view your subscription.'],
    es: ['Continúa en la aplicación SIX', 'Vuelve a la aplicación para confirmar el estado de tu suscripción.',
      'Volver a la aplicación SIX', 'Si la aplicación no se abre, abre SIX en tu celular y accede a tu suscripción. No necesitas pagar de nuevo.',
      'Volviste del checkout. Consulta tu suscripción en la aplicación.', 'Enlace de retorno inválido. Abre SIX y accede a tu suscripción.'],
  };
  const text = translations[locale] || translations.pt;
  document.documentElement.lang = translations[locale] ? locale : 'pt';
  document.title = text[0];
  document.getElementById('title').textContent = text[0];
  document.getElementById('help').textContent = text[3];
  const company = params.get('company') || '';
  const outcome = params.get('retorno');
  const valid = company.length > 0 && company.length <= 128 &&
    ['stripe', 'cancelado', 'portal'].includes(outcome);
  document.getElementById('message').textContent = !valid ? text[5] :
    outcome === 'cancelado' ? text[4] : text[1];
  if (!valid) return;
  // Fixed app scheme, never a caller-supplied URL. No token or payment authority.
  const target = new URL('com.sixoapp.billing://return');
  target.searchParams.set('company', company);
  target.searchParams.set('retorno', outcome);
  const button = document.getElementById('open-app');
  button.textContent = text[2];
  button.href = target.href;
  button.hidden = false;
  // HTTPS App/Universal Links are the automatic path. A user gesture on this
  // button is the browser-safe fallback; avoid repeated custom-scheme prompts.
})();
