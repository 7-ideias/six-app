// Payments require an authenticated commerce; the server resolves every price.
const input = new URLSearchParams(window.location.search);
const selection = new URLSearchParams();
for (const key of ['plan', 'interval', 'currency', 'locale']) {
  const value = input.get(key);
  if (value && value.length <= 100) selection.set(key, value);
}
window.location.replace(`/app/assinatura${selection.size ? `?${selection}` : ''}`);
