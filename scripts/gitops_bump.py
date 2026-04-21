#!/usr/bin/env python3
"""Bump an image tag inside an ArgoCD Application manifest.

Targets the inline `values: |` block and rewrites the `tag: "..."` line for
the given app/env. Keeps YAML formatting and comments untouched elsewhere.
"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys


def bump(env: str, app: str, tag: str) -> int:
    path = pathlib.Path(f"argocd-apps/{env}/{app}.yaml")
    if not path.exists():
        print(f"ERROR: {path} does not exist", file=sys.stderr)
        return 2
    text = path.read_text()
    new_text, n = re.subn(
        r'(tag:\s*)"[^"]*"',
        lambda m: f'{m.group(1)}"{tag}"',
        text,
        count=1,
    )
    if n == 0:
        print(f"ERROR: no `tag: \"...\"` found in {path}", file=sys.stderr)
        return 3
    if new_text == text:
        print(f"no-op: tag already {tag}")
        return 0
    path.write_text(new_text)
    print(f"bumped {app} @ {env} -> {tag}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--env", required=True)
    p.add_argument("--app", required=True)
    p.add_argument("--tag", required=True)
    args = p.parse_args()
    return bump(args.env, args.app, args.tag)


if __name__ == "__main__":
    sys.exit(main())
