# Codex Adaptation Implementation Plan

## Goal

Make `oh-story-claudecode` installable and understandable from Codex without breaking Claude Code/OpenClaw support.

## Tasks

1. Add a Codex plugin manifest and a shell check that validates the manifest points at `./skills/`.
2. Document Codex installation and usage in `README.md` and `README_EN.md`.
3. Add a Codex-native `AGENTS.md` with durable repo instructions and skill routing.
4. Update `story-setup` instructions/templates so Codex setup targets `AGENTS.md` and `.agents/skills/` while Claude setup keeps `.claude/`.
5. Re-run all existing CI shell checks plus the new Codex manifest check.

## Expected Files

- Create: `.codex-plugin/plugin.json`
- Create: `AGENTS.md`
- Create: `scripts/check-codex-plugin.sh`
- Modify: `README.md`
- Modify: `README_EN.md`
- Modify: `skills/story-setup/SKILL.md`
- Modify: `skills/story-setup/UPGRADING.md`
- Modify: `.github/workflows/cross-platform.yml`

## Verification Commands

```bash
bash scripts/check-codex-plugin.sh
bash scripts/static-check.sh
bash scripts/check-hook-regex-sync.sh
bash scripts/check-shared-files.sh
bash scripts/check-story-setup-deployment.sh
bash scripts/check-python-invocation.sh
bash scripts/test-charcount-portable.sh
bash scripts/test-charcount-portable.sh --stub
```
