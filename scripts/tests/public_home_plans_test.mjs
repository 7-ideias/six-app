import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

const html = readFileSync('web/public_home.html', 'utf8');
const homeSource = readFileSync('web/site-assets/js/home.js', 'utf8');
const plansSource = readFileSync('web/site-assets/js/home-plans.js', 'utf8');

test('home carrega catalogo publico configurado pelo backend', () => {
  assert.match(html, /data-public-plans/);
  assert.match(html, /site-assets\/js\/public-config\.js/);
  assert.match(html, /site-assets\/js\/home-plans\.js/);
  assert.match(plansSource, /loadPublicCheckoutPlans/);
  assert.match(plansSource, /plan\.billingPeriod === 'GRATUITO'/);
});

test('troca de idioma recarrega traducoes e moeda dos planos', () => {
  assert.match(homeSource, /sixapp:locale-changed/);
  assert.match(plansSource, /addEventListener\('sixapp:locale-changed'/);
});

test('home nao aceita preco nem html arbitrario pela URL ou API', () => {
  assert.equal(plansSource.includes('innerHTML'), false);
  assert.equal(plansSource.includes("URLSearchParams(window.location.search)"), false);
  assert.match(plansSource, /plan\.rawAmount/);
});


test('hero apresenta seis situacoes reais em um carrossel dedicado', () => {
  assert.equal((html.match(/data-hero-slide/g) || []).length, 6);
  assert.equal((html.match(/data-hero-caption/g) || []).length, 6);
  assert.equal((html.match(/data-hero-dot(?!s)/g) || []).length, 6);
  assert.match(html, /01-alerta-dono\.jpg/);
  assert.match(html, /02-atendimento-domiciliar\.jpg/);
  assert.match(html, /hero\.webp/);
  assert.match(html, /04-servico-em-campo\.jpg/);
  assert.match(html, /05-cliente-aprova-web\.jpg/);
  assert.match(html, /06-agenda-financeira\.jpg/);
});

test('hero troca a cada dois segundos com pausa, swipe e movimento reduzido', () => {
  assert.match(homeSource, /var interval = 2000/);
  assert.match(homeSource, /data-hero-toggle/);
  assert.match(homeSource, /touchStartY/);
  assert.match(homeSource, /Math\.abs\(distanceX\) <= Math\.abs\(distanceY\)/);
  assert.match(homeSource, /prefers-reduced-motion: reduce/);
  assert.match(homeSource, /sixappImpactHeroCarousel/);
});

test('microcopy do hero permanece completa em portugues, ingles e espanhol', () => {
  assert.equal((homeSource.match(/'hero\.scene\.one\.title'/g) || []).length, 3);
  assert.equal((homeSource.match(/'hero\.scene\.six\.title'/g) || []).length, 3);
  assert.equal((homeSource.match(/'hero\.carousel\.pause'/g) || []).length, 3);
  assert.match(homeSource, /O alerta encontra o dono onde ele estiver/);
  assert.match(homeSource, /The alert finds the owner wherever work is happening/);
  assert.match(homeSource, /La alerta encuentra al dueño donde esté trabajando/);
});


test('jornada reinicia o movimento sempre que volta para a viewport', () => {
  assert.match(html, /data-journey-motion/);
  assert.match(homeSource, /function setupJourneyMotion/);
  assert.match(homeSource, /intersectionRatio >= 0\.32/);
  assert.match(homeSource, /intersectionRatio < 0\.08/);
  assert.match(homeSource, /classList\.remove\('is-journey-active'\)/);
  assert.match(homeSource, /void track\.offsetWidth/);
});
