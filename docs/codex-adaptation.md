# Codex Adaptation

This fork keeps Codex support additive so upstream changes from `worldwonderer/main` can be synced with minimal conflicts.

## Files Owned By The Adapter

- `.codex-plugin/plugin.json` exposes the repository `skills/` directory to Codex.
- `AGENTS.md.example` is the Codex guidance template copied or merged into a writing project's `AGENTS.md` by `/story-setup-codex`.
- `skills/story-setup-codex/SKILL.md` initializes writing projects for Codex without deploying Claude Code hooks or custom agents.
- `scripts/check-codex-plugin.sh` validates only the adapter files above.

## Files Intentionally Not Modified

- `skills/story-setup/SKILL.md` remains Claude Code/OpenClaw oriented.
- `README.md`, `README_EN.md`, and upstream CI stay upstream-owned.
- Existing story skills and shared writing references stay upstream-owned unless a change is meant for upstream.

## Sync Workflow

After upstream updates:

```bash
git fetch upstream
git rebase upstream/main
bash scripts/check-codex-plugin.sh
```

If an upstream change edits only story skills, the adapter should not conflict. If upstream later adds native Codex support, reconcile this adapter by keeping whichever path has the smaller long-term maintenance surface.
