---
name: story-setup-codex
version: 1.0.0
description: |
  Codex 写作项目初始化。为网文写作项目部署 AGENTS.md、.story-deployed 等 Codex 兼容说明，不写入 Claude hooks/custom agents。
  触发方式：/story-setup-codex、「用 Codex 准备写书」「Codex 初始化写作项目」
---

# story-setup-codex：Codex 写作项目初始化

你是 Codex 写作基础设施部署器。你的职责是把 oh-story 的写作项目规则部署到用户项目目录，同时保持上游 Claude Code/OpenClaw 的 `/story-setup` 行为不变。

**执行铁律：Codex 初始化只做 additive/merge，不覆盖用户已有写作资料，不声称 Claude hooks 或 custom agents 在 Codex 自动生效。**

---

## Phase 1：检测项目状态

1. 确认当前目录是用户的写作项目根目录。
2. 检查是否存在 `.story-deployed`：
   - 不存在：按全新 Codex 初始化处理。
   - 存在且 `target_cli: codex`：询问用户是否重新合并 Codex 指南。
   - 存在且 `target_cli: claude-code`：不要删除 Claude 部署文件；询问用户是否额外添加 Codex 指南。
3. 检查是否存在 `AGENTS.md`：
   - 不存在：创建。
   - 存在：按「AGENTS.md 合并策略」合并。
4. 检查是否有书名目录：
   - 包含 `追踪/`、`设定/`、`大纲/`、`正文/` 任一目录的子目录视为候选书目。
   - 如果只发现一本书，可写入或更新 `.active-book`。
   - 如果发现多本书，列出候选项并让用户选择是否更新 `.active-book`。

## Phase 2：部署 Codex 兼容层

### 2.1 从模板部署 AGENTS.md

读取已安装 oh-story 插件根目录的 `AGENTS.md.example`，将其作为 Codex 项目规则模板：

- 如果目标项目没有 `AGENTS.md`：直接复制 `AGENTS.md.example` 到目标项目 `AGENTS.md`。
- 如果目标项目已有 `AGENTS.md`：按「AGENTS.md 合并策略」把 `AGENTS.md.example` 的 oh-story Codex 内容追加或替换到目标文件。
- 如果找不到 `AGENTS.md.example`：使用下面的内置最小模板继续部署，并在安装报告中写明 `Template Source: embedded fallback`。

`AGENTS.md.example` 的模板内容应覆盖以下核心语义：

```md
# Writing Project Guidance

This is a Chinese web-novel writing project using oh-story skills in Codex.

## Active CLI

- Codex reads durable guidance from AGENTS.md.
- Claude Code hooks and custom agents under .claude/ are advisory unless this environment verifies support for them.
- If subagent tooling is unavailable, run the requested review/write role in the main session and report solo fallback.

## Story Workflow

- Use /story for routing.
- Use /story-long-write for long-form writing.
- Use /story-short-write for short-form writing.
- Use /story-review for quality review.
- Use /story-deslop for AI-tone cleanup.

## Project State

- .active-book stores the active book directory.
- {书名}/追踪/上下文.md stores durable writing context when present.
- Do not overwrite existing manuscript, outline, character, setting, or tracking files without explicit user approval.
```

### 2.2 创建或更新 `.story-deployed`

写入 YAML key/value 格式：

```yaml
deployed_at: <UTC timestamp>
agents_version: 0
setup_skill_version: story-setup-codex-1.0.0
target_cli: codex
resolver_strategy: codex-plugin-skills
references_dir: skills
```

说明：
- `agents_version: 0` 表示没有部署 Claude custom agents。
- 如果项目已有 Claude Code `.story-deployed`，不要删除它；先询问用户是否将 sentinel 切换为 Codex，或只追加 AGENTS.md。

### 2.3 可选项目本地 skills

默认不复制 skills。Codex 插件已通过 `.codex-plugin/plugin.json` 暴露仓库 `skills/`。

只有当用户明确需要项目本地可移植副本时，才复制当前包的 `skills/` 到目标项目 `.agents/skills/oh-story/skills/`，并在安装报告中说明这是手动副本，不会自动跟随上游更新。

## AGENTS.md 合并策略

用户已有 `AGENTS.md` 时：
1. 优先识别 `<!-- OH_STORY_CODEX_START -->` 与 `<!-- OH_STORY_CODEX_END -->` 标记，只替换标记内内容。
2. 如果没有标记，保留用户全文，在文末追加从 `AGENTS.md.example` 读取的 oh-story Codex section，并包裹标记。
3. 不删除用户自定义规则、项目背景、禁用命令、写作设定或团队约定。
4. 如果用户已有同名 section 且语义冲突，先询问用户保留哪一版。

推荐追加块：

```md
<!-- OH_STORY_CODEX_START -->
## Oh Story Codex

- Use /story for intent routing.
- In Codex, use /story-setup-codex for setup. The upstream /story-setup remains Claude Code/OpenClaw oriented.
- Claude hooks and custom agents are not assumed active in Codex.
- If subagent tooling is unavailable, use solo fallback and state that in the report.
<!-- OH_STORY_CODEX_END -->
```

## Phase 3：验证安装

1. 确认 `AGENTS.md` 存在。
2. 确认 `AGENTS.md` 包含来自 `AGENTS.md.example` 的 oh-story Codex 说明，或包含 `OH_STORY_CODEX_START` 标记。
3. 确认 `.story-deployed` 存在且包含 `target_cli: codex`，除非用户选择只追加指南而不切换 sentinel。
4. 如果更新了 `.active-book`，确认路径存在。
5. 输出安装报告：
   - 列出已创建或合并的文件。
   - 写明 `Template Source: AGENTS.md.example | embedded fallback`。
   - 明确说明未自动部署 `.claude/hooks/` 和 `.claude/agents/`。
   - 提醒用户后续使用 `/story`、`/story-long-write`、`/story-short-write`、`/story-review`。

## 与上游 `/story-setup` 的边界

- 不修改上游 `skills/story-setup/SKILL.md`。
- 不写 `.claude/settings.local.json`。
- 不注册 Claude hooks。
- 不声称 `.claude/agents/` 在 Codex 自动注册为 subagent。
- 用户明确要求 Claude Code/OpenClaw 部署时，转交上游 `/story-setup`。
