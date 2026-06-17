---
name: story-setup
version: 1.2.0
description: |
  网文写作工具集基础设施部署。将 Codex/Claude Code/OpenClaw 所需的项目说明、skills、hooks/rules/agents 等基础设施部署到用户项目目录。
  触发方式：/story-setup、「准备写书」「帮我搭一下环境」「配置写作项目」
metadata:
  openclaw:
    source: https://github.com/worldwonderer/oh-story-claudecode
---

# story-setup：网文写作工具集基础设施部署

你是写作基础设施部署器。将网文写作工具集的全套基础设施部署到用户项目目录；根据目标 CLI 区分 Codex 与 Claude Code/OpenClaw 的落盘结构。

**执行铁律：不覆盖用户已有配置，合并而非替换。**

---

## Phase 1：检测项目状态

1. 检查当前目录是否已部署过（存在 `.story-deployed`）
   - 如果已存在 → 使用 AskUserQuestion 确认是否重新部署
2. 检查是否有书名目录（包含 `追踪/` 子目录的目录，或用户自定义结构）
   - 有 → 识别为长篇项目，显示当前项目信息
   - 无 → 识别为新项目或短篇项目
3. 检测目标 CLI：
   - 当前环境明显是 Codex，或用户明确说“适配 Codex / 用 Codex / AGENTS.md” → `target_cli: codex`
   - 当前环境明显是 Claude Code/OpenClaw，或用户明确说“Claude Code / OpenClaw” → `target_cli: claude-code`
   - 无法判断 → 用 AskUserQuestion 询问二选一：`Codex` 或 `Claude Code/OpenClaw`
4. 如果目标是 Claude Code/OpenClaw，检查 `.claude/settings.local.json` 是否存在
   - 存在 → 读取现有配置，后续合并
   - 不存在 → 后续创建新文件
   如果目标是 Codex，检查 `AGENTS.md` 是否存在，后续按 `AGENTS.md 合并策略` 处理
5. 检查 `.active-book` 文件是否存在
   - 存在 → 显示当前活跃书目
   - 不存在 → 跳过

## Phase 2：部署基础设施

使用 AskUserQuestion 确认部署位置后，依次执行。

### 2.0 部署清单（机械可检查）

| Source path | Target path | Owner class | Merge mode | Validation check |
|-------------|-------------|-------------|------------|------------------|
| `skills/story-setup/references/templates/CLAUDE.md.tmpl` | `CLAUDE.md` (`target_cli=claude-code`) | user+managed | marker/section merge | contains story skill routing sections |
| `skills/story-setup/references/templates/CLAUDE.md.tmpl` | `AGENTS.md` (`target_cli=codex`) | user+managed | marker/section merge | contains Codex compatibility and story skill routing sections |
| `skills/story-setup/references/templates/hooks/` | `.claude/hooks/` (`target_cli=claude-code`) | story-setup managed | recursive replace | `session-*.sh`, `detect-story-gaps.sh`, `validate-story-commit.sh`, `guard-outline-before-prose.sh`, `lib/common.sh`, `lib/sentinel.sh` exist |
| `skills/story-setup/references/templates/rules/*.md` | `.claude/rules/*.md` (`target_cli=claude-code`) | story-setup managed | replace | every rule contains `paths` frontmatter |
| `skills/story-setup/references/templates/agents/*.md` | `.claude/agents/*.md` (`target_cli=claude-code`) | story-setup managed | replace | 7 agent files exist |
| `skills/story-setup/references/agent-references/*.md` | `.claude/skills/story-setup/references/agent-references/*.md` (`target_cli=claude-code`) | story-setup managed | replace | every `story-setup/references/agent-references/*.md` reference resolves |
| installed package `skills/*` | `.agents/skills/*` (`target_cli=codex`, optional project-local copy) | story-setup managed | replace managed skill dirs only | every copied skill has `SKILL.md` |
| `skills/story-setup/references/agent-references/*.md` | `.agents/skills/story-setup/references/agent-references/*.md` (`target_cli=codex`) | story-setup managed | replace | every `story-setup/references/agent-references/*.md` reference resolves |
| `skills/story-setup/references/templates/settings-hooks.json` | `.claude/settings.local.json` (`target_cli=claude-code`) | user+managed | merge by hook command | hook JSON valid and registered commands deduped |
| `skills/story-setup/references/templates/上下文.md.tmpl` | `{书名}/追踪/上下文.md` | user state | create only if absent | never overwrite existing writing context |
| generated sentinel | `.story-deployed` | story-setup managed | replace | contains `agents_version`, `setup_skill_version`, `target_cli`, `resolver_strategy`, `references_dir` |

### 2.1 部署项目说明文件

- 读取 `skills/story-setup/references/templates/CLAUDE.md.tmpl`
- 替换占位符（见下方「模板占位符」段）
- `target_cli=claude-code`：写入项目根目录 `CLAUDE.md`（如已存在，按「CLAUDE.md 合并策略」处理）
- `target_cli=codex`：写入项目根目录 `AGENTS.md`（如已存在，按「AGENTS.md 合并策略」处理），并追加 Codex 兼容说明：
  - Codex 从 `AGENTS.md` 读取长期项目规则
  - 项目本地 skills 放在 `.agents/skills/`
  - Claude Code custom agents 与 `.claude/settings.local.json` hooks 不假定在 Codex 自动生效
  - 子代理不可用时，按同一角色提示在主会话 solo fallback
- 手动部署或用户想先看模板时，可参考仓库根目录 `AGENTS.md.example`

### 2.2 部署 Hooks

- 仅 `target_cli=claude-code` 自动注册 hooks。
- **递归复制完整目录树**：将 `skills/story-setup/references/templates/hooks/` 复制到用户项目 `.claude/hooks/`
- 必须保留子目录 `lib/`，其中：
  - `lib/common.sh` 提供 `project_root`、`discover_active_book`、`discover_all_books`
  - `lib/sentinel.sh` 提供 `.story-deployed` 字段读取
- 只需对 `.claude/hooks/*.sh` 设置执行权限（`chmod +x`）；`lib/*.sh` 由 hook `source`，不要求可执行位
- `target_cli=codex` 时不要写 `.claude/settings.local.json`，也不要声称这些 hooks 会自动生效；安装报告中列出“可手动运行的脚本”作为 advisory 工具。

### 2.3 部署 Rules

- 仅 `target_cli=claude-code` 部署 `.claude/rules/`。
- 读取 `skills/story-setup/references/templates/rules/` 下所有 `.md` 文件
- 复制到用户项目的 `.claude/rules/` 目录

### 2.4 部署 Agents

- 仅 `target_cli=claude-code` 部署 `.claude/agents/`。
- 读取 `skills/story-setup/references/templates/agents/` 下所有 `.md` 文件
- 复制到用户项目的 `.claude/agents/` 目录
- Agent 文件属于 story-setup 管理文件，可安全覆盖；版本升级时按 `UPGRADING.md` 的版本检测结果重新部署
- **部署后必须新开会话**：Claude Code 只在会话启动时扫描 `.claude/agents/` 注册 subagent。当前会话内新部署的 agent 不会立即可用——必须让用户新开一个 Claude Code 会话，`story-architect`/`narrative-writer` 等 custom agent 才会注册成 `subagent_type`；否则 story-review、story-long-write 等想 spawn 时会拿到「subagent_type 不可用」并降级 solo（单视角）。这一步必须在安装报告里明确告知用户（见 Phase 3 第 6 步）。

### 2.4.1 Agent 兼容性处理

- Agent frontmatter 以 Claude Code 为主；OpenClaw/qclaw 等只要支持 AgentSkills，未知字段（如 `memory`、`skills`、`disallowedTools`）应被忽略。若目标工具报 frontmatter 错误，保留 `name`、`description`、`tools` 三项，删除不支持字段后再部署。
- 部署到项目后，agent 内引用的参考资料必须走 `story-setup/references/agent-references/*.md` 这一本 skill 内复制路径；不要跨 skill 引用其他 skill 的 references。若全局安装路径不同，优先用项目内 `.claude/skills/` 或 `skills/` 作为规范路径前缀，其次用工具的 skill 搜索能力，不要假定固定绝对路径。

### 2.4.2 部署 Agent References

- 将 `skills/story-setup/references/agent-references/` 下所有 `.md` 复制到项目内 `.claude/skills/story-setup/references/agent-references/`
- 如目标项目已经使用项目本地 `skills/` 目录，也可以同步复制到 `skills/story-setup/references/agent-references/` 作为 fallback，但不得只复制 fallback 而遗漏 `.claude/skills/` 主路径
- 校验：凡 agent 或 reference 中出现 `story-setup/references/agent-references/<file>.md`，源包与目标包都必须存在 `<file>.md`

### 2.4.3 Codex 项目本地 Skills

- `target_cli=codex` 时，如用户选择项目本地安装，将当前包的 `skills/` 复制到项目 `.agents/skills/`
- 只覆盖 story-setup 管理的同名 skill 目录，不删除用户自建的其他 `.agents/skills/*`
- Agent references 主路径改为 `.agents/skills/story-setup/references/agent-references/`
- 校验：`.agents/skills/story/SKILL.md`、`.agents/skills/story-setup/SKILL.md` 存在，且 agent reference bundle 完整

### 2.5 部署 Session State 模板

- 读取 `skills/story-setup/references/templates/上下文.md.tmpl`
- 仅当已识别为长篇书目且 `{书名}/追踪/` 已存在时，创建缺失的 `{书名}/追踪/上下文.md`
- 如果目标文件已存在，不覆盖；短篇项目不得因此创建 `追踪/` 目录

### 2.6 合并 Hooks 注册到 settings.local.json

> 兼容性说明：`settings-hooks.json` 中 PreToolUse 的 `if` 字段使用 Claude Code hook 条件语法，需要运行环境支持 hook-level if。若目标工具不支持该字段，hook 脚本本身仍会自检并 advisory-only 退出；部署时可删除该 `if` 字段并保留 matcher + command。

- 仅 `target_cli=claude-code` 执行本步骤
- 读取 `skills/story-setup/references/templates/settings-hooks.json`
- 读取用户项目的 `.claude/settings.local.json`（如存在）
- 合并 hooks 配置（按「settings-hooks.json 合并算法」处理）
- 写入 `.claude/settings.local.json`

### 2.7 创建部署标记

- 创建 `.story-deployed` 文件（sentinel file）
- 写入以下字段（YAML `key: value` 格式，hook 用 `references/templates/hooks/lib/sentinel.sh` 读取）：
  ```
  deployed_at: <date -u +"%Y-%m-%dT%H:%M:%SZ">
  agents_version: 11
  setup_skill_version: 1.2.0
  target_cli: claude-code | codex
  resolver_strategy: project-local-skill-reference
  references_dir: .claude/skills/story-setup/references/agent-references | .agents/skills/story-setup/references/agent-references
  ```
- 此文件供 session-start.sh 和写作 skill 检测部署状态，避免重复提示
- `target_cli=claude-code` 时，同时创建一次性标记文件 `.claude/.agents-pending-restart`（空文件即可）。session-start.sh 在下一个会话启动时据此确认 agents 已随新会话注册，并自动删除该标记——用来向用户确认「重启已生效」。
- 如果 `.story-deployed` 已存在但无 `agents_version` 或版本 < 11，提示用户重新运行 story-setup 以更新 Codex/Claude 部署说明、hooks/agents/rules/reference bundle（具体变更见 `UPGRADING.md`）

## Phase 3：验证安装

1. `target_cli=claude-code` 验证 hooks 注册：
   - 检查 `.claude/settings.local.json` 中的 hooks 字段是否正确
   - 检查 `.claude/hooks/` 下的脚本是否存在且有执行权限
   - 检查 `.claude/hooks/lib/common.sh` 与 `.claude/hooks/lib/sentinel.sh` 是否存在
2. `target_cli=claude-code` 验证 rules 路径：
   - 检查 `.claude/rules/` 下的规则文件是否存在且包含 `paths` frontmatter
3. `target_cli=claude-code` 验证 agents：
   - 检查 `.claude/agents/` 下的 7 个 agent 定义文件是否存在
4. 验证 reference bundle：
   - 检查 `.claude/skills/story-setup/references/agent-references/` 下 reference 文件完整
   - `target_cli=codex` 时改查 `.agents/skills/story-setup/references/agent-references/`
   - 检查所有 `story-setup/references/agent-references/<file>.md` 都能解析到 deployed bundle
5. 验证部署标记：
   - 检查 `.story-deployed` 是否存在且包含时间戳、`agents_version: 11`、`setup_skill_version: 1.2.0`、`target_cli`、`resolver_strategy`、`references_dir`
6. 输出安装报告：
   - 列出所有已部署的文件
   - 列出需要注意的事项（如已有配置已合并）
   - `target_cli=claude-code`：**⚠️ 重启提示（必须醒目输出）**：本次部署写入了 `.claude/agents/`，但这些 custom agent 只在「会话启动」时才会被 Claude Code 注册成 `subagent_type`。**请新开一个 Claude Code 会话再开始写作**，否则当前会话里 story-review / story-long-write 等想 spawn `story-architect`、`narrative-writer` 等时会拿到「subagent_type 不可用」并降级 solo（单视角，失去多 agent 协作）。判断是否生效：新会话里跑 `/story-review`，报告头若是 `Effective Mode: full/lean` 即注册成功；若是 `Fallback: ... -> solo` 说明还在旧会话或未注册。
   - `target_cli=codex`：明确说明 Claude custom agents/hooks 未自动注册；有 subagent 工具时可并行，否则 solo fallback
   - 提示用户可以开始使用 `/story-long-write` 或 `/story-short-write`

---

## 模板占位符

| 占位符 | 替换规则 | 示例 |
|--------|----------|------|
| `{项目名}` | 用户项目名称或目录名 | 《剑来》、《暗卫》 |
| `{书名}` | 书名目录名（与目录一致） | 与 `{项目名}` 相同，或用户自定义 |
| `{目标平台}` | 目标发布平台 | 起点、番茄、晋江、知乎盐言 |
| `{作者名}` | 用户笔名或昵称 | 未指定时用「作者」 |

替换时去掉花括号。如果用户未指定项目名，用当前目录名。未指定的占位符保留原样不替换。

## CLAUDE.md 合并策略

用户已有 CLAUDE.md 时，按 marker/section 合并：
1. 优先识别 story-setup 管理块标记（如果旧项目已有标记，只替换标记内内容）
2. 无标记时，读取用户现有 CLAUDE.md，按 `##` 标题切分为 section map
3. 读取模板 CLAUDE.md.tmpl，同样切分
4. 模板中的标准 section（Skill 路由表、文件结构、协作规则、Context Recovery、语言）**覆盖**用户同名 section
5. 用户独有的 section（自定义内容）**保留**不动
6. 未知冲突用 AskUserQuestion 让用户选择保留哪个版本

## AGENTS.md 合并策略

用户已有 AGENTS.md 时，按 marker/section 合并：
1. 优先识别 story-setup 管理块标记（如果旧项目已有标记，只替换标记内内容）
2. 无标记时，读取用户现有 AGENTS.md，按 `##` 标题切分为 section map
3. 读取模板 CLAUDE.md.tmpl 并转换为 Codex 语义：标题改为 Codex Guidance，Compact 段改为 Context Recovery，追加 Codex Compatibility
4. 模板中的标准 section（Skill 路由表、文件结构、协作规则、Context Recovery、Codex Compatibility、语言）覆盖用户同名 section
5. 用户独有 section 保留不动
6. 未知冲突用 AskUserQuestion 让用户选择保留哪个版本

## settings-hooks.json 合并算法

hooks 注册合并按 command 字段去重：
1. 读取用户现有 `.claude/settings.local.json`（如存在），提取 hooks 部分
2. 读取 `settings-hooks.json` 模板，提取要注册的 hooks
3. 对每个 hook event（SessionStart、PreToolUse 等）：
   - 用户已有的 hook command → 保留，不重复添加
   - 模板中的新 hook command → append 到对应 event 的 hooks 数组
   - 用户独有的其他配置（permissions、env 等）→ 完整保留
4. 写入合并后的完整 settings.local.json

## 重新部署

- `.story-deployed` 不存在 → 全新安装，Phase 2 全部执行
- `.story-deployed` 存在且 `agents_version: 11` → 提示已部署，AskUserQuestion 确认是否重新部署
- `.story-deployed` 存在但 `agents_version` < 11 → 提示需要更新，重新执行 Phase 2；Claude 目标覆盖 agents/hooks/rules/reference bundle，CLAUDE.md 和 settings.local.json 走合并策略；Codex 目标更新 AGENTS.md 和 `.agents/skills/` 管理副本

---

## 参考资料

| 文件 | 用途 |
|------|------|
| references/templates/CLAUDE.md.tmpl | 项目根 CLAUDE.md 模板 |
| references/templates/hooks/ | 7 个 hook 脚本模板 + `lib/common.sh`/`lib/sentinel.sh` |
| references/templates/rules/ | 4 条 path-scoped 规则模板 |
| references/templates/agents/ | 7 个 agent 定义模板（story-architect, character-designer, narrative-writer, consistency-checker, story-researcher, story-explorer, chapter-extractor） |
| references/agent-references/ | Agent 模板自带的参考资料副本；Claude 目标部署到 `.claude/skills/story-setup/references/agent-references/`，Codex 目标部署到 `.agents/skills/story-setup/references/agent-references/`，避免跨 skill references |
| references/templates/settings-hooks.json | hooks 注册 JSON 片段 |
| references/templates/上下文.md.tmpl | 写作上下文模板 |

---

## 流程衔接

**流水线：** 部署
**位置：** 初始化（最前置）

| 时机 | 跳转到 | 命令 |
|---|---|---|
| 部署完成，开始写作 | story-long-write / story-short-write | `/story-long-write` 或 `/story-short-write` |
| 导入已有小说做拆解 | story-import | `/story-import` |
| 需要浏览器登录态（扫榜/拆文取原文） | browser-cdp | `/browser-cdp` |
