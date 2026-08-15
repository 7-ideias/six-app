#!/usr/bin/env python3
"""Compatibility wrapper for the Flutter Web hot reload script."""

from __future__ import annotations

import os
import sys
from pathlib import Path


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    root_dir = Path(__file__).resolve().parents[1]
    script_path = root_dir / "scripts" / "dev_web_hot_reload.sh"

    if not script_path.is_file():
        print(
            f"[ERRO SIX] Script ausente: {script_path}",
            file=sys.stderr,
        )
        return 1

    os.chdir(root_dir)
    os.execv("/usr/bin/env", ["env", "bash", str(script_path), *args])
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
