import assert from 'node:assert/strict';
import test from 'node:test';
import { installPublicHomeSessionGuard } from '../../web/site-assets/js/home-session.mjs';

function browser() {
  const events = new Map();
  const destinations = [];
  return {
    events, destinations,
    SIXAPP_PUBLIC_CONFIG: { apiBaseUrl: 'https://api.example.test' },
    navigator: { userAgent: 'Desktop' },
    addEventListener: (name, listener) => events.set(name, listener),
    location: { replace: (path) => destinations.push(path) },
  };
}

test('active session on public home replaces URL with /app', async () => {
  const windowLike = browser();
  const check = installPublicHomeSessionGuard({ windowLike, restoreSession: async ({apiBaseUrl}) => {
    assert.equal(apiBaseUrl, 'https://api.example.test');
    return true;
  }});
  await check();
  assert.deepEqual(windowLike.destinations, ['/app']);
});

test('anonymous visitor stays on public home', async () => {
  const windowLike = browser();
  const check = installPublicHomeSessionGuard({windowLike, restoreSession: async () => false});
  await check();
  assert.deepEqual(windowLike.destinations, []);
});

test('Back restoring cached home rechecks the session acquired after first visit', async () => {
  const windowLike = browser();
  let authenticated = false;
  let calls = 0;
  const check = installPublicHomeSessionGuard({windowLike, restoreSession: async () => {
    calls++;
    return authenticated;
  }});
  await check();
  assert.deepEqual(windowLike.destinations, []);
  authenticated = true;
  windowLike.events.get('pageshow')({persisted: true});
  await check();
  assert.equal(calls, 2);
  assert.deepEqual(windowLike.destinations, ['/app']);
});

test('in-flight requests are shared and temporary failures leave public content available', async () => {
  const windowLike = browser();
  let reject;
  let calls = 0;
  const check = installPublicHomeSessionGuard({windowLike, restoreSession: () => {
    calls++;
    return new Promise((_, fail) => { reject = fail; });
  }});
  const first = check();
  windowLike.events.get('pageshow')({persisted: true});
  assert.equal(check(), first);
  reject(new Error('offline'));
  await first;
  assert.equal(calls, 1);
  assert.deepEqual(windowLike.destinations, []);
});

test('after logout, cached public home remains accessible with an invalid session', async () => {
  const windowLike = browser();
  const check = installPublicHomeSessionGuard({windowLike, restoreSession: async () => false});
  await check();
  windowLike.events.get('pageshow')({persisted: true});
  await check();
  assert.deepEqual(windowLike.destinations, []);
});
