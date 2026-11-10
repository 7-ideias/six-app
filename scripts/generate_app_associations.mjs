import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const output = process.argv[2] || 'build/web/.well-known';
const team = process.env.SIX_IOS_TEAM_ID || '7FH3353D87';
if (!/^[A-Z0-9]{10}$/.test(team)) throw new Error('Invalid SIX_IOS_TEAM_ID');
const fingerprints = (process.env.SIX_ANDROID_APP_LINK_SHA256 || '')
  .split(',').map(value => value.trim().toUpperCase()).filter(Boolean);
for (const value of fingerprints) {
  if (!/^([A-F0-9]{2}:){31}[A-F0-9]{2}$/.test(value)) {
    throw new Error('Invalid SIX_ANDROID_APP_LINK_SHA256 certificate fingerprint');
  }
}
mkdirSync(output, { recursive: true });
writeFileSync(join(output, 'apple-app-site-association'), JSON.stringify({
  applinks: { apps: [], details: [{
    appID: team + '.com.sixoapp.app',
    paths: ['/mobile/billing-return'],
  }] },
}, null, 2));
writeFileSync(join(output, 'assetlinks.json'), JSON.stringify(fingerprints.length ? [{
  relation: ['delegate_permission/common.handle_all_urls'],
  target: { namespace: 'android_app', package_name: 'br.com.seteideias.appplanilha',
    sha256_cert_fingerprints: fingerprints },
}] : [], null, 2));
if (!fingerprints.length) {
  console.warn('SIX_ANDROID_APP_LINK_SHA256 not configured: Android uses the return-to-app button until verified links are configured.');
}
