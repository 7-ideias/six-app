import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

const loginSource = readFileSync(
  'lib/presentation/screens/login_page_web.dart',
  'utf8',
);
const adminServiceSource = readFileSync(
  'lib/core/services/admin_portal_service.dart',
  'utf8',
);

test('login iniciado em /admin segue para /admin/dashboard', () => {
  assert.match(loginSource, /if \(uri\.path == '\/admin'\)/);
  assert.match(loginSource, /return '\/admin\/dashboard';/);
});

test('403 administrativo nao e tratado como sessao expirada', () => {
  assert.doesNotMatch(
    adminServiceSource,
    /response\.statusCode == 401 \|\| response\.statusCode == 403/,
  );
  assert.match(
    adminServiceSource,
    /Sessão expirada\. Faça login novamente\./,
  );
  assert.match(
    adminServiceSource,
    /não possui autorização para acessar o portal administrativo/,
  );
});
