#!/usr/bin/env python3
"""Local production-like web server for the composed SixApp web build."""

from __future__ import annotations

import argparse
import errno
import mimetypes
import shutil
import sys
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlsplit


DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 39441
ROOT_DIR = Path(__file__).resolve().parents[1]
DEFAULT_WEB_ROOT = ROOT_DIR / "build" / "web"

REQUIRED_BUILD_FILES = (
    "index.html",
    "login.html",
    "register.html",
    "forgot-password.html",
    "onboarding.html",
    "checkout.html",
    "flutter.html",
)

PUBLIC_HTML_ROUTES = {
    "/": "index.html",
    "/login": "login.html",
    "/register": "register.html",
    "/forgot-password": "forgot-password.html",
    "/onboarding": "onboarding.html",
    "/checkout": "checkout.html",
}

FLUTTER_EXACT_ROUTES = {
    "/login/flutter",
    "/register/flutter",
    "/forgot-password/flutter",
    "/onboarding/flutter",
    "/checkout/flutter",
}

FLUTTER_PREFIXES = (
    "/app",
    "/admin",
)

SENSITIVE_PUBLIC_FILES = {
    "login.html",
    "register.html",
    "forgot-password.html",
    "onboarding.html",
    "checkout.html",
}


def validate_build(web_root: Path) -> None:
    missing = [name for name in REQUIRED_BUILD_FILES if not (web_root / name).is_file()]
    if not missing:
        return

    missing_list = "\n".join(f"- {web_root / name}" for name in missing)
    raise SystemExit(
        "[DEV WEB] Arquivos obrigatorios ausentes:\n"
        f"{missing_list}\n\n"
        "Execute primeiro:\n"
        "bash scripts/build_web_with_public_home.sh"
    )


def _is_flutter_prefix(path: str) -> bool:
    return any(path == prefix or path.startswith(f"{prefix}/") for prefix in FLUTTER_PREFIXES)


class DevWebProductionHandler(BaseHTTPRequestHandler):
    server_version = "SixDevWebProductionLike/1.0"
    web_root: Path

    def do_GET(self) -> None:
        self._handle_request(send_body=True)

    def do_HEAD(self) -> None:
        self._handle_request(send_body=False)

    def do_POST(self) -> None:
        self._log_route("POST", self._raw_log_path(), "405")
        self.send_response(HTTPStatus.METHOD_NOT_ALLOWED)
        self.send_header("Allow", "GET, HEAD")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()

    def log_message(self, format: str, *args: object) -> None:  # noqa: A002
        return

    def _handle_request(self, send_body: bool) -> None:
        method = self.command
        raw_path = self._raw_log_path()
        safe_path = self._safe_request_path(raw_path)

        if safe_path is None:
            self._log_route(method, raw_path, "404")
            self._send_not_found(send_body)
            return

        static_path = self._static_file_for_path(safe_path)
        if static_path is not None:
            self._log_route(method, safe_path, "static")
            self._send_file(static_path, send_body, sensitive=static_path.name in SENSITIVE_PUBLIC_FILES)
            return

        if safe_path == "/home":
            self._log_route(method, safe_path, "307 /")
            self._send_redirect("/", send_body)
            return

        route_file = PUBLIC_HTML_ROUTES.get(safe_path)
        if route_file is not None:
            self._log_route(method, safe_path, route_file)
            self._send_file(
                self.web_root / route_file,
                send_body,
                sensitive=route_file in SENSITIVE_PUBLIC_FILES,
            )
            return

        if safe_path in FLUTTER_EXACT_ROUTES or _is_flutter_prefix(safe_path):
            self._log_route(method, safe_path, "flutter.html")
            self._send_file(self.web_root / "flutter.html", send_body, sensitive=False)
            return

        self._log_route(method, safe_path, "404")
        self._send_not_found(send_body)

    def _raw_log_path(self) -> str:
        parsed = urlsplit(self.path)
        return parsed.path or "/"

    def _safe_request_path(self, raw_path: str) -> str | None:
        try:
            decoded_path = unquote(raw_path, errors="strict")
        except UnicodeDecodeError:
            return None

        if not decoded_path.startswith("/"):
            decoded_path = f"/{decoded_path}"

        if "\x00" in decoded_path or "\\" in decoded_path:
            return None

        segments = [segment for segment in decoded_path.split("/") if segment]
        if any(segment == ".." for segment in segments):
            return None

        if decoded_path != "/" and decoded_path.endswith("/"):
            decoded_path = decoded_path.rstrip("/")

        return decoded_path or "/"

    def _static_file_for_path(self, safe_path: str) -> Path | None:
        relative_parts = [part for part in safe_path.split("/") if part and part != "."]
        candidate = (self.web_root / Path(*relative_parts)).resolve()

        try:
            candidate.relative_to(self.web_root)
        except ValueError:
            return None

        if candidate.is_file():
            return candidate

        return None

    def _send_file(self, file_path: Path, send_body: bool, *, sensitive: bool) -> None:
        stat = file_path.stat()
        content_type = self._content_type_for(file_path)

        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(stat.st_size))
        self.send_header("Last-Modified", self.date_time_string(stat.st_mtime))
        self.send_header("X-Content-Type-Options", "nosniff")

        if sensitive:
            self.send_header("Cache-Control", "no-store, max-age=0")
            self.send_header("Referrer-Policy", "strict-origin-when-cross-origin")
            self.send_header("X-Frame-Options", "DENY")

        self.end_headers()

        if send_body:
            with file_path.open("rb") as source:
                shutil.copyfileobj(source, self.wfile)

    def _send_redirect(self, location: str, send_body: bool) -> None:
        body = b"Temporary Redirect\n"
        self.send_response(HTTPStatus.TEMPORARY_REDIRECT)
        self.send_header("Location", location)
        self.send_header("Cache-Control", "no-store, max-age=0")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body) if send_body else 0))
        self.end_headers()

        if send_body:
            self.wfile.write(body)

    def _send_not_found(self, send_body: bool) -> None:
        body = b"Not Found\n"
        self.send_response(HTTPStatus.NOT_FOUND)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body) if send_body else 0))
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()

        if send_body:
            self.wfile.write(body)

    def _content_type_for(self, file_path: Path) -> str:
        if file_path.suffix == ".wasm":
            return "application/wasm"

        content_type, encoding = mimetypes.guess_type(file_path)
        if content_type is None:
            content_type = "application/octet-stream"

        if encoding:
            content_type = f"{content_type}; encoding={encoding}"

        if (
            content_type.startswith("text/")
            or content_type in {"application/javascript", "application/json"}
            or file_path.suffix in {".js", ".mjs"}
        ):
            content_type = f"{content_type}; charset=utf-8"

        return content_type

    def _log_route(self, method: str, path: str, target: str) -> None:
        print(f"[DEV WEB] {method} {path} -> {target}", flush=True)


class DevWebHTTPServer(ThreadingHTTPServer):
    allow_reuse_address = True


def create_http_server(host: str, port: int, web_root: Path) -> DevWebHTTPServer:
    resolved_root = web_root.resolve()

    class Handler(DevWebProductionHandler):
        pass

    Handler.web_root = resolved_root
    return DevWebHTTPServer((host, port), Handler)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Serve build/web with local Vercel-like rewrites for SixApp web.",
    )
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="Porta local. Padrao: 39441.")
    parser.add_argument("--host", default=DEFAULT_HOST, help="Host de bind. Padrao: 127.0.0.1.")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    web_root = DEFAULT_WEB_ROOT.resolve()

    validate_build(web_root)

    try:
        server = create_http_server(args.host, args.port, web_root)
    except OSError as exc:
        if exc.errno == errno.EADDRINUSE:
            print(
                f"[DEV WEB] Porta ocupada: {args.host}:{args.port}\n"
                "Nao foi encerrado nenhum processo automaticamente.\n"
                "Sugestao: tente outra porta com --port, por exemplo:\n"
                "python3 scripts/dev_web_production_server.py --port 39442",
                file=sys.stderr,
            )
            return 1
        raise

    print(f"[DEV WEB] Servindo {web_root} em http://{args.host}:{args.port}", flush=True)
    print("[DEV WEB] Pressione Ctrl+C para encerrar.", flush=True)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[DEV WEB] Encerrando servidor local.", flush=True)
    finally:
        server.server_close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
