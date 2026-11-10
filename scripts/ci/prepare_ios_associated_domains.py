"""Match the optional Universal Links capability to the installed profile.

The app's custom billing URL scheme remains available without this capability.
Never change Push Notifications, Keychain, or authentication entitlements.
"""
import fnmatch
import os
from pathlib import Path
import plistlib
import sys


ASSOCIATED_DOMAINS = "com.apple.developer.associated-domains"


def prepare(profile_path, entitlements_path):
    profile = plistlib.loads(Path(profile_path).read_bytes())
    path = Path(entitlements_path)
    requested = plistlib.loads(path.read_bytes())
    domains = requested.get(ASSOCIATED_DOMAINS, [])
    allowed = profile.get("Entitlements", {}).get(ASSOCIATED_DOMAINS, [])
    if not isinstance(domains, list) or not isinstance(allowed, list):
        raise ValueError("Invalid Associated Domains entitlement")
    enabled = bool(domains) and all(
        any(fnmatch.fnmatchcase(domain, pattern) for pattern in allowed)
        for domain in domains
    )
    if not enabled:
        requested.pop(ASSOCIATED_DOMAINS, None)
        path.write_bytes(plistlib.dumps(requested, sort_keys=False))
        print("::warning::Provisioning profile sem Associated Domains compativel. "
              "Este build usa o botao Voltar para o aplicativo SIX. "
              "Atualize IOS_PROVISIONING_PROFILE_BASE64 para habilitar Universal Links.")
    if os.environ.get("GITHUB_ENV"):
        with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as env:
            env.write(f"IOS_ASSOCIATED_DOMAINS_ENABLED={str(enabled).lower()}\n")
    print(f"Universal Links enabled: {str(enabled).lower()}")
    return enabled


def verify(expected, signed_path):
    signed = plistlib.loads(Path(signed_path).read_bytes())
    domains = signed.get(ASSOCIATED_DOMAINS, [])
    if expected not in ("true", "false"):
        raise ValueError("Missing expected Universal Links capability")
    if expected == "true" and "applinks:www.sixoapp.com" not in domains:
        raise ValueError("Signed app is missing the requested Universal Links domain")
    if expected == "false" and domains:
        raise ValueError("Signed app unexpectedly contains Associated Domains")


if __name__ == "__main__":
    if len(sys.argv) != 4 or sys.argv[1] not in ("prepare", "verify"):
        raise SystemExit("Usage: prepare_ios_associated_domains.py prepare PROFILE ENTITLEMENTS | verify true/false SIGNED_ENTITLEMENTS")
    if sys.argv[1] == "prepare":
        prepare(sys.argv[2], sys.argv[3])
    else:
        verify(sys.argv[2], sys.argv[3])
