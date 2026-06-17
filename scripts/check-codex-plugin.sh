#!/bin/bash
# check-codex-plugin.sh — validate Codex plugin packaging metadata.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/.codex-plugin/plugin.json"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

echo "Codex plugin check"
echo "=================="
echo "Repo: $REPO_ROOT"

[ -f "$MANIFEST" ] || fail "missing .codex-plugin/plugin.json"

PYBIN=""
for candidate in python3 python py; do
  if "$candidate" -c "" >/dev/null 2>&1; then
    PYBIN="$candidate"
    break
  fi
done
[ -n "$PYBIN" ] || fail "no usable Python interpreter found"

"$PYBIN" - "$MANIFEST" "$REPO_ROOT" <<'PY'
import json
import pathlib
import re
import sys

manifest_path = pathlib.Path(sys.argv[1])
repo_root = pathlib.Path(sys.argv[2])

try:
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
except json.JSONDecodeError as exc:
    raise SystemExit(f"FAIL: plugin.json is not valid JSON: {exc}") from exc

required = {
    "name": str,
    "version": str,
    "description": str,
    "author": dict,
    "skills": str,
    "interface": dict,
}
for key, typ in required.items():
    if key not in data:
        raise SystemExit(f"FAIL: missing required field: {key}")
    if not isinstance(data[key], typ):
        raise SystemExit(f"FAIL: field {key} must be {typ.__name__}")

if data["name"] != "oh-story-claudecode":
    raise SystemExit("FAIL: name must be oh-story-claudecode")

if not re.fullmatch(r"\d+\.\d+\.\d+", data["version"]):
    raise SystemExit("FAIL: version must be strict semver")

if data["skills"] != "./skills/":
    raise SystemExit("FAIL: skills must point at ./skills/")

if not (repo_root / "skills" / "story" / "SKILL.md").is_file():
    raise SystemExit("FAIL: skills/story/SKILL.md is missing")

author = data["author"]
if author.get("name") != "worldwonderer":
    raise SystemExit("FAIL: author.name must be worldwonderer")

interface = data["interface"]
for key in ["displayName", "shortDescription", "longDescription", "developerName", "category"]:
    if not interface.get(key):
        raise SystemExit(f"FAIL: interface.{key} is required")

prompts = interface.get("defaultPrompt", [])
if not isinstance(prompts, list) or not (1 <= len(prompts) <= 3):
    raise SystemExit("FAIL: interface.defaultPrompt must contain 1-3 prompts")
for prompt in prompts:
    if not isinstance(prompt, str) or len(prompt) > 128:
        raise SystemExit("FAIL: each default prompt must be a string <= 128 chars")

print("  OK plugin.json schema")
print("  OK skills path")
print("  OK interface metadata")
PY

echo ""
echo "OK: Codex plugin manifest is valid"
