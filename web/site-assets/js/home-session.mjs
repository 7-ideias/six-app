import {
  resolvePublicApiConfig,
  restorePublicLoginSession,
  shouldBlockPublicLoginOnMobile,
} from './login-core.mjs';

// The public home is a separate HTML document. Flutter's route guard cannot
// run when Back restores this document, including from the back/forward cache.
export function installPublicHomeSessionGuard({
  windowLike = globalThis.window,
  restoreSession = restorePublicLoginSession,
} = {}) {
  if (!windowLike || shouldBlockPublicLoginOnMobile(windowLike)) return null;
  let pending = null;
  const checkSession = () => {
    if (pending) return pending;
    pending = (async () => {
      try {
        const { apiBaseUrl } = resolvePublicApiConfig(windowLike.SIXAPP_PUBLIC_CONFIG);
        if (await restoreSession({ apiBaseUrl })) {
          // Replace the public entry; do not add another login/public hop.
          windowLike.location.replace('/app');
        }
      } catch (_) {
        // A public visitor must still be able to read the site during an outage.
        // A local flag or a failed request is never proof of authentication.
      }
    })().finally(() => { pending = null; });
    return pending;
  };
  windowLike.addEventListener('pageshow', (event) => {
    if (event.persisted) void checkSession();
  });
  void checkSession();
  return checkSession;
}

if (typeof window !== 'undefined') installPublicHomeSessionGuard();
