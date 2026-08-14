#!/usr/bin/env python3
"""Tests for scripts/dev_web_production_server.py."""

from __future__ import annotations

import http.client
import importlib.util
import tempfile
import threading
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SERVER_PATH = REPO_ROOT / "scripts" / "dev_web_production_server.py"

spec = importlib.util.spec_from_file_location("dev_web_production_server", SERVER_PATH)
server_module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(server_module)


class DevWebProductionServerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.web_root = Path(self.temp_dir.name)
        self._write_build_fixture()

        self.server = server_module.create_http_server("127.0.0.1", 0, self.web_root)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.port = self.server.server_address[1]

    def tearDown(self) -> None:
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=5)
        self.temp_dir.cleanup()

    def test_public_html_routes(self) -> None:
        self.assert_route("/", "public-home")
        self.assert_route("/login", "public-login")
        self.assert_route("/register", "public-register")
        self.assert_route("/forgot-password", "public-forgot-password")
        self.assert_route("/onboarding", "public-onboarding")
        self.assert_route("/checkout", "public-checkout")

    def test_flutter_routes(self) -> None:
        self.assert_route("/app", "flutter-app")
        self.assert_route("/app/deep-link", "flutter-app")
        self.assert_route("/admin", "flutter-app")
        self.assert_route("/admin/deep-link", "flutter-app")
        self.assert_route("/login/flutter", "flutter-app")
        self.assert_route("/register/flutter", "flutter-app")
        self.assert_route("/forgot-password/flutter", "flutter-app")
        self.assert_route("/onboarding/flutter", "flutter-app")
        self.assert_route("/checkout/flutter", "flutter-app")

    def test_home_redirects_to_root(self) -> None:
        status, headers, body = self.request("/home")

        self.assertEqual(307, status)
        self.assertEqual("/", headers.get("Location"))
        self.assertIn("Temporary Redirect", body)

    def test_static_asset_is_served_without_rewrite(self) -> None:
        status, headers, body = self.request("/site-assets/css/login.css")

        self.assertEqual(200, status)
        self.assertIn("asset-fixture", body)
        self.assertIn("text/css", headers.get("Content-Type", ""))

    def test_unknown_route_returns_404(self) -> None:
        status, _, body = self.request("/rota-inexistente-sixapp")

        self.assertEqual(404, status)
        self.assertIn("Not Found", body)

    def test_path_traversal_is_blocked(self) -> None:
        status, _, body = self.request("/%2e%2e/%2e%2e/etc/passwd")

        self.assertEqual(404, status)
        self.assertIn("Not Found", body)

    def test_query_string_keeps_route_mapping_without_redirect(self) -> None:
        status, headers, body = self.request("/login?redirect=/app/atendimentos-tecnicos")

        self.assertEqual(200, status)
        self.assertNotIn("Location", headers)
        self.assertIn("public-login", body)

    def test_startup_validation_reports_missing_build_files(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            with self.assertRaises(SystemExit) as failure:
                server_module.validate_build(Path(temp_dir))

        message = str(failure.exception)
        self.assertIn("Arquivos obrigatorios ausentes", message)
        self.assertIn("Execute primeiro:", message)
        self.assertIn("bash scripts/build_web_with_public_home.sh", message)

    def assert_route(self, path: str, marker: str) -> None:
        status, _, body = self.request(path)

        self.assertEqual(200, status, path)
        self.assertIn(marker, body)

    def request(self, path: str) -> tuple[int, dict[str, str], str]:
        connection = http.client.HTTPConnection("127.0.0.1", self.port, timeout=5)
        try:
            connection.request("GET", path)
            response = connection.getresponse()
            body = response.read().decode("utf-8")
            headers = dict(response.getheaders())
            return response.status, headers, body
        finally:
            connection.close()

    def _write_build_fixture(self) -> None:
        pages = {
            "index.html": "public-home",
            "login.html": "public-login",
            "register.html": "public-register",
            "forgot-password.html": "public-forgot-password",
            "onboarding.html": "public-onboarding",
            "checkout.html": "public-checkout",
            "flutter.html": "flutter-app",
        }

        for filename, marker in pages.items():
            (self.web_root / filename).write_text(
                f'<!doctype html><meta name="sixapp-entrypoint" content="{marker}">',
                encoding="utf-8",
            )

        asset_path = self.web_root / "site-assets" / "css" / "login.css"
        asset_path.parent.mkdir(parents=True)
        asset_path.write_text("/* asset-fixture */", encoding="utf-8")


if __name__ == "__main__":
    unittest.main(verbosity=2)
