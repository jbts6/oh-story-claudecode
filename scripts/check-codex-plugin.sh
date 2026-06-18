#!/usr/bin/env bash
# check-codex-plugin.sh — validate additive Codex adapter files.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$ROOT" ]; then
  echo "FAIL: not in a git repository" >&2
  exit 1
fi

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file() {
  [ -f "$ROOT/$1" ] || fail "missing file: $1"
}

assert_grep() {
  local pattern="$1"
  local file="$2"
  local message="$3"
  grep -Eq "$pattern" "$ROOT/$file" || fail "$message ($file)"
}

assert_file ".codex-plugin/plugin.json"
assert_file "AGENTS.md.example"
assert_file "skills/story-setup-codex/SKILL.md"

python3 -m json.tool "$ROOT/.codex-plugin/plugin.json" >/dev/null

assert_grep '"name"[[:space:]]*:[[:space:]]*"oh-story-claudecode"' ".codex-plugin/plugin.json" "plugin name mismatch"
assert_grep '"skills"[[:space:]]*:[[:space:]]*"./skills/"' ".codex-plugin/plugin.json" "plugin must expose ./skills/"
assert_grep '"interface"' ".codex-plugin/plugin.json" "plugin interface metadata missing"
assert_grep 'story-setup-codex' ".codex-plugin/plugin.json" "plugin default prompts should expose Codex setup"

assert_grep 'Codex Compatibility' "AGENTS.md.example" "AGENTS.md.example must document Codex compatibility"
assert_grep 'story-setup-codex' "AGENTS.md.example" "AGENTS.md.example must route Codex setup to story-setup-codex"
assert_grep 'Claude Code custom agents.*not assumed|custom agents.*not assumed' "AGENTS.md.example" "AGENTS.md.example must avoid claiming Claude agents work in Codex"
assert_grep 'check-codex-plugin\.sh' "AGENTS.md.example" "AGENTS.md.example must document adapter validation"

assert_grep '^name:[[:space:]]*story-setup-codex' "skills/story-setup-codex/SKILL.md" "Codex setup skill frontmatter name missing"
assert_grep 'AGENTS\.md' "skills/story-setup-codex/SKILL.md" "Codex setup skill must deploy AGENTS.md"
assert_grep 'AGENTS\.md\.example' "skills/story-setup-codex/SKILL.md" "Codex setup skill must source AGENTS.md.example"
assert_grep 'target_cli:[[:space:]]*codex' "skills/story-setup-codex/SKILL.md" "Codex setup skill must document codex sentinel"
assert_grep '不写 \.claude/settings\.local\.json|不注册 Claude hooks' "skills/story-setup-codex/SKILL.md" "Codex setup skill must not register Claude hooks"

echo "OK: Codex adapter files are present and internally consistent"
