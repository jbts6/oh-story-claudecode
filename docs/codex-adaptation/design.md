# Codex Adaptation Design

## Goal

Add first-class Codex support while preserving the existing Claude Code and OpenClaw workflows.

## Scope

- Package the repository as a Codex plugin with a `.codex-plugin/plugin.json` manifest that exposes the existing `skills/` tree.
- Document Codex installation and usage alongside the current Claude Code/OpenClaw instructions.
- Extend `story-setup` guidance so project setup can target Codex:
  - Codex projects use `AGENTS.md` for durable project instructions.
  - Codex project-local skills live under `.agents/skills/` when a setup copy is needed.
  - Claude Code projects keep the existing `.claude/CLAUDE.md`, `.claude/hooks/`, `.claude/agents/`, and `.claude/settings.local.json` layout.
- Make agent orchestration language platform-aware:
  - Claude Code can use custom agents from `.claude/agents/`.
  - Codex should use available subagent tools when present; otherwise the main session follows the same role prompts and reports solo fallback.

## Non-Goals

- Do not rewrite the novel-writing methodology.
- Do not remove or rename existing Claude Code files.
- Do not require Codex-specific hooks unless the repository can validate the format locally.
- Do not split the package into a separate Codex-only repository.

## Compatibility Strategy

The existing Claude paths remain canonical for Claude Code. Codex support is additive:

- `.codex-plugin/plugin.json` makes the repo installable as one Codex plugin.
- `AGENTS.md` mirrors the root writing-tool instructions in a Codex-native surface.
- `story-setup` documents a `target_cli` value of `codex` and records it in `.story-deployed`.
- Runtime workflows keep their current fallback behavior. If subagent orchestration is unavailable in Codex, the skill still completes in solo mode.

## Verification

- Existing CI shell checks must continue to pass:
  - `bash scripts/static-check.sh`
  - `bash scripts/check-hook-regex-sync.sh`
  - `bash scripts/check-shared-files.sh`
  - `bash scripts/check-story-setup-deployment.sh`
  - `bash scripts/check-python-invocation.sh`
  - `bash scripts/test-charcount-portable.sh`
  - `bash scripts/test-charcount-portable.sh --stub`
- Add lightweight validation that the Codex plugin manifest exists and points at `./skills/`.
