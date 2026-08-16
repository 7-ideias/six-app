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
