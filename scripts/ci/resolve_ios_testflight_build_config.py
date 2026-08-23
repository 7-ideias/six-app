#!/usr/bin/env python3

import argparse
import os
import pathlib
import plistlib
import re
import shutil
import subprocess
import sys
from typing import NoReturn
from urllib.parse import urlparse


PUBSPEC_PATH = pathlib.Path("pubspec.yaml")
APP_CONFIG_PATH = pathlib.Path("lib/core/config/app_config.dart")
INFO_PLIST_PATH = pathlib.Path("ios/Runner/Info.plist")

REQUIRED_DART_DEFINES = (
    "API_BASE_URL",
    "PUBLIC_FRONTEND_URL",
)


class ResolutionError(Exception):
    def __init__(self, config_name: str):
        super().__init__(config_name)
        self.config_name = config_name


def fail(config_name: str) -> NoReturn:
    print(f"::error::Nao foi possivel resolver {config_name}", file=sys.stderr)
    raise ResolutionError(config_name)


def read_text(path: pathlib.Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        fail(path.as_posix())


def parse_pubspec_version(path: pathlib.Path) -> tuple[str, int]:
    for raw_line in read_text(path).splitlines():
        stripped_line = raw_line.strip()
        if not stripped_line.startswith("version:"):
            continue
        version_value = stripped_line.partition(":")[2].split("#", 1)[0].strip()
        version_value = version_value.strip("'\"")
        match = re.fullmatch(r"(\d+\.\d+\.\d+)\+(\d+)", version_value)
        if not match:
            fail("APP_VERSION")
        build_name, build_number = match.groups()
        return build_name, int(build_number)
    fail("APP_VERSION")


def find_matching_parenthesis(source: str, body_start: int) -> int:
    depth = 1
    in_single_quote = False
    escaping = False

    for index in range(body_start, len(source)):
        character = source[index]
        if in_single_quote:
            if escaping:
                escaping = False
            elif character == "\\":
                escaping = True
            elif character == "'":
                in_single_quote = False
            continue

        if character == "'":
            in_single_quote = True
        elif character == "(":
            depth += 1
        elif character == ")":
            depth -= 1
            if depth == 0:
                return index

    fail("APP_CONFIG_DART_DEFINES")


def extract_dart_define_defaults(path: pathlib.Path) -> dict[str, str]:
    source = read_text(path)
    marker = "String.fromEnvironment("
    defaults: dict[str, str] = {}
    search_start = 0

    while True:
        marker_index = source.find(marker, search_start)
        if marker_index < 0:
            break

        body_start = marker_index + len(marker)
        body_end = find_matching_parenthesis(source, body_start)
        body = source[body_start:body_end]

        env_name_match = re.match(r"\s*'([^']+)'", body, re.DOTALL)
        default_value_match = re.search(r"defaultValue\s*:\s*'([^']+)'", body)

        if env_name_match and default_value_match:
            defaults[env_name_match.group(1)] = default_value_match.group(1)

        search_start = body_end + 1

    if not defaults:
        fail("APP_CONFIG_DART_DEFINES")

    return defaults


def validate_required_value(name: str, value: str) -> str:
    if not value or not value.strip():
        fail(name)
    return value.strip()


def validate_url(name: str, value: str) -> str:
    cleaned_value = validate_required_value(name, value)
    parsed = urlparse(cleaned_value)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        fail(name)
    return cleaned_value


def load_info_plist(path: pathlib.Path) -> dict:
    try:
        with path.open("rb") as file_handle:
            return plistlib.load(file_handle)
    except FileNotFoundError:
        fail("GOOGLE_IOS_CLIENT_ID")


def read_plist_value(path: pathlib.Path, key: str, fallback_plist: dict) -> str:
    plistbuddy_path = pathlib.Path("/usr/libexec/PlistBuddy")
    if plistbuddy_path.exists():
        result = subprocess.run(
            [str(plistbuddy_path), "-c", f"Print :{key}", str(path)],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            return result.stdout.strip()

    plutil_path = shutil.which("plutil")
    if plutil_path:
        result = subprocess.run(
            [plutil_path, "-extract", key, "raw", "-o", "-", str(path)],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            return result.stdout.strip()

    value = fallback_plist.get(key, "")
    return value.strip() if isinstance(value, str) else ""


def validate_google_ios_client_id(client_id: str, info_plist: dict) -> str:
    cleaned_client_id = validate_required_value("GOOGLE_IOS_CLIENT_ID", client_id)
    if not re.fullmatch(
        r"\d+-[A-Za-z0-9._-]+\.apps\.googleusercontent\.com", cleaned_client_id
    ):
        fail("GOOGLE_IOS_CLIENT_ID")

    reverse_client_id = "com.googleusercontent.apps." + cleaned_client_id.removesuffix(
        ".apps.googleusercontent.com"
    )

    url_types = info_plist.get("CFBundleURLTypes", [])
    url_schemes: list[str] = []
    for url_type in url_types:
        schemes = url_type.get("CFBundleURLSchemes", [])
        if isinstance(schemes, list):
            url_schemes.extend(str(scheme).strip() for scheme in schemes if scheme)

    if reverse_client_id not in url_schemes:
        fail("GOOGLE_IOS_CLIENT_ID")

    return cleaned_client_id


def validate_encryption_flag(info_plist: dict) -> None:
    if info_plist.get("ITSAppUsesNonExemptEncryption") is not False:
        fail("ITSAppUsesNonExemptEncryption")


def append_env_file(path: pathlib.Path, resolved_values: dict[str, str]) -> None:
    with path.open("a", encoding="utf-8") as env_file:
        for key, value in resolved_values.items():
            env_file.write(f"{key}={value}\n")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--env-file",
        default=os.environ.get("GITHUB_ENV"),
        help="Arquivo no formato GITHUB_ENV para receber as variaveis resolvidas.",
    )
    parser.add_argument(
        "--run-number",
        type=int,
        default=int(os.environ.get("GITHUB_RUN_NUMBER", "0")),
        help="Numero da execucao para compor o APP_BUILD_NUMBER.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.env_file:
        fail("GITHUB_ENV")

    build_name, pubspec_build_number = parse_pubspec_version(PUBSPEC_PATH)
    build_number = pubspec_build_number + args.run_number

    app_config_defaults = extract_dart_define_defaults(APP_CONFIG_PATH)
    resolved_dart_defines = {}
    for env_name in REQUIRED_DART_DEFINES:
        resolved_dart_defines[env_name] = validate_url(
            env_name,
            app_config_defaults.get(env_name, ""),
        )

    info_plist = load_info_plist(INFO_PLIST_PATH)
    validate_encryption_flag(info_plist)

    ios_client_id = read_plist_value(INFO_PLIST_PATH, "GIDClientID", info_plist)
    validated_ios_client_id = validate_google_ios_client_id(ios_client_id, info_plist)

    resolved_values = {
        "FLUTTER_BUILD_NAME": build_name,
        "FLUTTER_BUILD_NUMBER": str(build_number),
        "APP_VERSION": build_name,
        "APP_BUILD_NUMBER": str(build_number),
        "API_BASE_URL": resolved_dart_defines["API_BASE_URL"],
        "PUBLIC_FRONTEND_URL": resolved_dart_defines["PUBLIC_FRONTEND_URL"],
        "GOOGLE_IOS_CLIENT_ID": validated_ios_client_id,
    }

    append_env_file(pathlib.Path(args.env_file), resolved_values)

    print(f"Build name: {build_name}")
    print(f"Build number: {build_number}")
    print("Resolved API_BASE_URL")
    print("Resolved PUBLIC_FRONTEND_URL")
    print("Resolved GOOGLE_IOS_CLIENT_ID from ios/Runner/Info.plist")

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ResolutionError:
        raise SystemExit(1)
