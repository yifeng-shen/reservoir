# ai-integration.md · 跨 AI 接入配置

> 本文件说明如何把 `reservoir` 接入 ChatGPT、Claude、Gemini、Cursor 以及各类 Agent 平台，
> 并定义「AI 任务完成后自动写回」的规则。
>
> 仓库地址：<https://github.com/yifeng-shen/reservoir>
> 维护者：[@yifeng-shen](https://github.com/yifeng-shen) · 协议版本 v1 · 2026-10-31

---

## 1. 设计原则

| 原则 | 含义 |
| --- | --- |
| **单一事实来源** | 同一份 Markdown 服务所有 AI，不在各平台重复维护画像 |
| **读写分离** | 身份事实只读；AI 的观察写 inbox，人类决定是否转正 |
| **纯文本优先** | 无数据库、无私有格式；任何模型都能读，任何设备都能改 |
| **可追溯** | 所有修改进 Git；禁止强推/删除；每天自动快照 |
| **最小权限** | 只读场景发只读令牌；写回只允许追加，不允许重写 |

数据流：

```text
                 ┌──────────────────────────────┐
                 │  GitHub: yifeng-shen/reservoir │
                 │  identity / workflow / memory │
                 └──────────────┬───────────────┘
        raw URL / API / git / MCP│
     ┌──────────┬──────────┬─────┴─────┬──────────┐
     ▼          ▼          ▼           ▼          ▼
  ChatGPT    Claude     Gemini      Cursor     Agent 平台
     │          │          │           │          │
     └──────────┴────┬─────┴───────────┴──────────┘
                     ▼
         任务结束后写 memory/inbox.md
                     ▼
            人工每周筛选转正
```

---

## 2. 机器可读协议

### 2.1 文件头（YAML Frontmatter）

每个档案文件开头都有：

```yaml
---
schema: reservoir/v1
id: identity/profile          # 全局唯一，等于「目录/文件名」
ai_tag: AI-READONLY           # 权限标签
owner: yifeng-shen
created: "2026-10-31"
updated: "2026-10-31"
version: 1
tags: [identity, profile]
summary: "一句话说明本文件内容"
---
```

AI 应先解析 `ai_tag` 与 `id`，再决定读取与写入行为。

### 2.2 标题标签

Frontmatter 之后的第一行是带标签的 H1：

```markdown
# AI-READONLY: 个人身份核心信息
```

| 标签 | 可写性 | 目录 |
| --- | --- | --- |
| `AI-READONLY` | 只读，禁止改写/删除 | `identity/`、根文档、`schema/` |
| `AI-APPEND` | 仅可追加到 `## 追加区` | `memory/`、`archive/` |
| `AI-EDIT` | 可编辑，须登记变更记录 | `workflow/`、`skills/` |
| `AI-GENERATED` | 禁止手改，由脚本生成 | `index.json`、`dist/` |

### 2.3 记忆条目

```markdown
### 2026-10-31 · 标题
- **场景**：…
- **结论**：…
- **原因**：…
- **边界**：…
- **来源**：ChatGPT
- **置信度**：高
```

机器可用正则 `^### (\d{4}-\d{2}-\d{2}) · (.+)$` 切分条目。

### 2.4 稳定读取地址

| 资源 | URL |
| --- | --- |
| 协作契约 | `https://raw.githubusercontent.com/yifeng-shen/reservoir/main/AGENTS.md` |
| 身份 | `https://raw.githubusercontent.com/yifeng-shen/reservoir/main/identity/profile.md` |
| 沟通风格 | `https://raw.githubusercontent.com/yifeng-shen/reservoir/main/workflow/communication.md` |
| 偏好 | `https://raw.githubusercontent.com/yifeng-shen/reservoir/main/memory/preferences.md` |
| 文件清单 | `https://raw.githubusercontent.com/yifeng-shen/reservoir/main/index.json` |
| LLM 索引 | `https://raw.githubusercontent.com/yifeng-shen/reservoir/main/llms.txt` |

> 用 `main` 分支的 raw 地址，永远读最新版本。需要固定版本时用 commit SHA 取代 `main`。

---

## 3. 四种接入方式

### 方式 A：直接读 raw URL（零配置）

适合所有支持联网读取的 AI。把下面这段作为系统提示词/项目指令：

```text
在我的任务开始前，先读取以下文件（按顺序）：
1. https://raw.githubusercontent.com/yifeng-shen/reservoir/main/AGENTS.md
2. https://raw.githubusercontent.com/yifeng-shen/reservoir/main/identity/profile.md
3. https://raw.githubusercontent.com/yifeng-shen/reservoir/main/workflow/communication.md
4. https://raw.githubusercontent.com/yifeng-shen/reservoir/main/memory/preferences.md

读取后不要复述内容，直接按其中的沟通风格和权限规则工作。
任务结束时，按 AGENTS.md 的写入协议生成记忆条目；
若你无法写入 GitHub，把条目以 markdown 代码块输出给我。
```

优点：无需令牌、不会泄露写权限。
缺点：只能读；部分平台不允许访问任意 URL。

### 方式 B：GitHub API（适合 Actions / 自建 Agent）

```bash
# 读取单个文件（返回原始文本，避免 base64 解码）
curl -sL \
  -H "Accept: application/vnd.github.raw+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/yifeng-shen/reservoir/contents/identity/profile.md

# 列出全部文件
curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/yifeng-shen/reservoir/git/trees/main?recursive=1"
```

速率限制：匿名 60 次/小时，认证 5000 次/小时。
只读场景请使用 **Fine-grained PAT → Contents: Read-only**，不要用账号密码。

**ChatGPT Custom GPT Actions** 的现成 OpenAPI 配置见
[`integrations/openai-actions.openapi.yaml`](integrations/openai-actions.openapi.yaml)：
它直接调用公开的 raw 接口，**无需认证、不消耗 API 配额**，导入即可读取核心档案。
需要读取任意文件或私有仓库时，再改用上面的 Contents API + 只读 PAT。

### 方式 C：git clone（适合编程 Agent）

```bash
git clone https://github.com/yifeng-shen/reservoir.git ~/.reservoir
```

- Claude Code：在仓库内运行，自动读取 `CLAUDE.md` → `AGENTS.md`。
- Cursor / Windsurf / Codex：把仓库加入工作区，或在规则中引用 `AGENTS.md`。
- 任何 CLI Agent：`cd ~/.reservoir` 后直接读写文件。

写回时遵循提交规范：

```bash
git add -A
git commit -m "memory(auto): 记录本周偏好 [ai:claude]"
git push origin main
```

### 方式 D：MCP Server（推荐给支持 MCP 的客户端）

[`mcp/server.py`](mcp/server.py) 是一个零依赖（Python 标准库）的 MCP Server，提供四个工具：

| 工具 | 作用 | 权限 |
| --- | --- | --- |
| `reservoir_read` | 读取指定文件 | 只读 |
| `reservoir_search` | 全文搜索档案 | 只读 |
| `reservoir_append` | 追加到 `memory/inbox.md` | 仅追加 |
| `reservoir_log_decision` | 追加决策到 `memory/decisions.md` | 仅追加 |

Claude Desktop 配置（`~/Library/Application Support/Claude/claude_desktop_config.json`）：

```json
{
  "mcpServers": {
    "reservoir": {
      "command": "python3",
      "args": ["/Users/syf/.reservoir/mcp/server.py"],
      "env": { "RESERVOIR_ROOT": "/Users/syf/.reservoir" }
    }
  }
}
```

Cursor 配置（`.cursor/mcp.json`）：

```json
{
  "mcpServers": {
    "reservoir": {
      "command": "python3",
      "args": ["/Users/syf/.reservoir/mcp/server.py"],
      "env": { "RESERVOIR_ROOT": "/Users/syf/.reservoir" }
    }
  }
}
```

> 把路径换成你本机的克隆位置。MCP Server 只操作本地文件，
> 推送仍由 `scripts/sync.sh` 或你的 Agent 完成。

---

## 4. 平台配置

### 4.1 ChatGPT

| 能力 | 做法 |
| --- | --- |
| 读 | **Custom GPT → Actions**：导入 `integrations/openai-actions.openapi.yaml`，认证选 **None**（公开 raw 接口）；或把 `dist/reservoir-snapshot.md` 上传到 GPT 知识库 |
| 读（团队版） | Projects 中上传快照文件；若账号支持 GitHub 连接器，可直接连接本仓库 |
| 写 | 通过 Actions 调 GitHub Contents API（需要写权限 PAT，**不推荐**）；更安全的做法是让 GPT 输出条目，由你粘贴到 `memory/inbox.md` |
| 建议 | 给 Custom GPT 的 Instructions 直接粘贴第 3 节方式 A 的提示词 |

### 4.2 Claude

| 能力 | 做法 |
| --- | --- |
| 读 | Projects → 上传 `dist/reservoir-snapshot.md`，或逐个上传 `identity/`、`workflow/` 文件；Claude Code 直接克隆仓库 |
| 写 | 接 MCP Server（方式 D），用 `reservoir_append` 写入 inbox；或 Claude Code 内直接编辑并 `git push` |
| 建议 | Project Instructions 粘贴方式 A 提示词；在 Claude Code 中本仓库的 `CLAUDE.md` 会自动加载 |

### 4.3 Gemini

| 能力 | 做法 |
| --- | --- |
| 读 | Gems → 上传快照/档案文件作为知识；Gemini CLI 在克隆目录中运行；支持 GitHub 扩展的版本可直接索引仓库 |
| 写 | 通过 git（Gemini CLI）或输出条目由你粘贴；不支持直接写时不要给它写权限 |
| 建议 | Gem 指令粘贴方式 A 提示词，并注明「引用档案时标注文件路径」 |

### 4.4 Agent 平台（Meta Muse、OpenAI Dots 等）

这类平台的能力差异较大，按以下顺序选择接入方式：

1. **支持 MCP** → 接入 `mcp/server.py`，获得读 + 追加写。
2. **支持自定义 HTTP 工具 / Function Calling** → 用 GitHub API 封装两个函数：
   `read_reservoir_file(path)` 与 `append_reservoir_memory(entry)`。
3. **只支持知识库导入** → 用 `scripts/export_snapshot.sh` 生成单文件快照上传，
   并设置每周重新上传（或让平台定时抓取 raw URL）。

无论哪种方式，都要求 Agent 遵守本文第 5 节的写入规则。
若平台不支持写回，让它把记忆条目输出为固定格式，由你统一收集。

### 4.5 编程 Agent（Cursor / Codex / Claude Code / Gemini CLI）

1. 克隆仓库到固定路径（如 `~/.reservoir`）。
2. 在 Agent 规则文件中引用 `AGENTS.md`（本仓库已提供 `CLAUDE.md`、`AGENTS.md`）。
3. 需要写回时，允许 Agent 执行 `git add/commit/push`，但禁止 force push。
4. 建议给 Agent 单独的分支策略：直接推 `main` 仅限追加型改动；结构性修改走 PR。

---

## 5. 写入协议（自动更新规则）

### 5.1 五条硬规则

1. **只写 inbox**：任何新观察默认追加到 `memory/inbox.md`，不直接改正式记忆。
2. **只追加**：`AI-APPEND` 文件禁止修改/删除历史条目；`AI-READONLY` 文件禁止任何写入。
3. **必须标注**：每条记忆带 `来源` 与 `置信度`；缺一不可。
4. **小步提交**：单次提交 ≤ 5 个文件、≤ 300 行；提交信息带 `[ai:<名字>]`。
5. **不碰敏感信息**：密钥、身份证、住址、他人隐私、公司机密一律不写。

### 5.2 触发时机

| 触发 | 写入位置 | 例子 |
| --- | --- | --- |
| 我明确说「以后都这样」 | `memory/preferences.md`（可直接转正） | 「以后代码都给完整版」 |
| 我纠正了 AI | `memory/inbox.md` | 「不对，先给结论」 |
| 完成一个重要决策 | `memory/decisions.md` | 技术选型、职业选择 |
| 项目结束 | `archive/projects.md` | 上线复盘 |
| 学会新技能 | `skills/mastered.md` | 等级从 L2 → L3 |

### 5.3 提交信息规范

```text
<type>(<scope>): <summary> [ai:<name>]

type: identity | workflow | memory | skills | archive | chore
scope: profile | preferences | decisions | ...
```

示例：

```text
memory(inbox): 记录代码评审的 3 条偏好 [ai:claude]
workflow(communication): 补充「不要用营销腔」 [ai:chatgpt]
```

### 5.4 冲突处理

- 本地与远端冲突：先 `git pull --rebase`，不要强推。
- 同一文件被两个 AI 修改：保留双方条目，人工合并。
- 发现历史条目错误：不要删除，追加一条「更正」并注明日期。

### 5.5 自动同步的三种实现

| 方式 | 适用 | 做法 |
| --- | --- | --- |
| GitHub Actions | 定时生成索引/快照 | `.github/workflows/snapshot.yml` 每天打 tag；`validate.yml` 每次推送校验 |
| 本地监听 | 你在电脑上编辑 | `./scripts/watch.sh`（需 `brew install fswatch`）自动 commit + push |
| Agent 定时任务 | 支持 cron 的 Agent 平台 | 每天/每周调用 `reservoir_append`，或运行 `scripts/sync.sh` |

---

## 6. 安全与版本控制

### 6.1 分支保护

`main` 已启用 Ruleset：

- 禁止删除分支
- 禁止 force push（非快进更新）
- 要求线性历史（禁止 merge commit）

查看：

```bash
gh api repos/yifeng-shen/reservoir/rulesets
```

### 6.2 快照与回退

- 每天 `snapshot/YYYY-MM-DD` 标签（由 Actions 自动创建），标签受保护、不可删除。
- 回退方式见 [`scripts/rollback.sh`](scripts/rollback.sh)：

```bash
./scripts/rollback.sh list
./scripts/rollback.sh show <commit>
./scripts/rollback.sh restore <commit> memory/inbox.md
./scripts/rollback.sh revert <commit>
```

### 6.3 密钥与隐私

- 已开启 Secret Scanning + Push Protection。
- 建议给 AI 的令牌：Fine-grained PAT，仅 `Contents: Read`，过期时间 ≤ 90 天。
- 公开仓库不要写：手机号、住址、身份证、银行卡、公司未公开数据、他人信息。
- 需要私密档案时，另建私有仓库并把本仓库作为「公开层」。

### 6.4 AI 误操作的兜底

| 风险 | 兜底 |
| --- | --- |
| 改坏身份文件 | 文件只读 + 分支保护 + 每日快照 |
| 删光记忆 | 禁止删除规则 + Git 历史 + 可 revert |
| 写入隐私 | Push Protection + 每周人工 review inbox |
| 令牌泄露 | 只读令牌 + 90 天过期 + 随时 revoke |

---

## 7. 快速接入清单

- [ ] 克隆仓库：`git clone https://github.com/yifeng-shen/reservoir.git`
- [ ] 填完 `identity/profile.md` 与 `workflow/communication.md`
- [ ] 运行 `python3 scripts/build_index.py` 生成索引
- [ ] ChatGPT：创建 Custom GPT，导入 Actions 配置 + 粘贴方式 A 提示词
- [ ] Claude：创建 Project，上传快照 + 粘贴方式 A 提示词；需要写回则配置 MCP
- [ ] Gemini：创建 Gem，上传文件 + 粘贴方式 A 提示词
- [ ] 编程 Agent：克隆到 `~/.reservoir`，确认能读到 `AGENTS.md`
- [ ] 跑一次 `./scripts/sync.sh` 验证推送
- [ ] 确认 Actions 中 `validate` 与 `snapshot` 均为绿色

---

## 8. 故障排查

| 现象 | 原因 | 解决 |
| --- | --- | --- |
| raw URL 404 | 分支名错 / 文件未推送 | 确认是 `main`，`git push` 后重试 |
| API 返回 base64 | 未加 raw Accept 头 | 加 `Accept: application/vnd.github.raw+json` |
| API 403 rate limit | 匿名额度用完 | 用只读 PAT 认证 |
| AI 改了只读文件 | 未读 AGENTS.md | 回退 + 在提示词中强调权限标签 |
| Actions 失败 | 占位符严格模式 / 格式错误 | 看日志，运行 `python3 scripts/validate.py` |
| MCP 连不上 | 路径/解释器错误 | 用绝对路径，先手动 `echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' \| python3 mcp/server.py` 测试 |

---

_本文件随协议演进更新；结构性修改请走 PR。_
