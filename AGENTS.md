# oh-story-claudecode — Codex Guidance

This repository contains a web-novel writing skill pack. Keep changes focused on executable skill behavior, deployment templates, validation scripts, and documentation.

## Skill Routing

Use these skills when the user invokes the matching command or natural-language intent:

| Command | Skill | Purpose |
|---|---|---|
| `/story` `/网文` | `story` | Route fuzzy writing intents to the right tool |
| `/story-setup` `/准备写书` | `story-setup` | Deploy writing-project infrastructure |
| `/story-long-write` `/写长篇` | `story-long-write` | Long-form writing workflow |
| `/story-short-write` `/写短篇` | `story-short-write` | Short-form writing workflow |
| `/story-long-analyze` `/长篇拆文` | `story-long-analyze` | Long-form deconstruction |
| `/story-short-analyze` `/短篇拆文` | `story-short-analyze` | Short-form deconstruction |
| `/story-long-scan` `/长篇扫榜` | `story-long-scan` | Long-form market scanning |
| `/story-short-scan` `/短篇扫榜` | `story-short-scan` | Short-form market scanning |
| `/story-deslop` `/去AI味` | `story-deslop` | Remove AI writing traces |
| `/story-review` `/审查` | `story-review` | Multi-perspective review or solo fallback |
| `/story-import` `/导入` | `story-import` | Reverse-import an existing novel |
| `/story-cover` `/封面` | `story-cover` | Generate cover art |
| `/browser-cdp` | `browser-cdp` | Browser automation via Chrome CDP |

## Codex Compatibility

- Codex reads durable project guidance from `AGENTS.md`.
- Codex skills are exposed by `.codex-plugin/plugin.json` through the repository `skills/` directory.
- Claude Code custom agents under `.claude/agents/` are not assumed to be available in Codex. If subagent tooling is unavailable, execute the same role prompt in the main session and report solo fallback.
- Claude Code hook configuration under `.claude/settings.local.json` is not treated as Codex hook configuration. Do not claim those hooks run automatically in Codex unless verified in the active environment.

## Validation

Before PRs, run:

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

Keep shared reference files synchronized when editing duplicated writing theory files.
