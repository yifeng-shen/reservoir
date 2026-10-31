<div align="center">

# Reservoir · 个人记忆水库

**一次搭建，全平台复用的跨 AI 个人记忆系统**

把「我是谁、我怎么工作、我做过什么决定、我会什么」写成一套机器可读的 Markdown，
让 ChatGPT、Claude、Gemini、Cursor 以及各类 Agent 都能读取同一份事实来源。

[![validate](https://github.com/yifeng-shen/reservoir/actions/workflows/validate.yml/badge.svg)](https://github.com/yifeng-shen/reservoir/actions/workflows/validate.yml)
[![snapshot](https://github.com/yifeng-shen/reservoir/actions/workflows/snapshot.yml/badge.svg)](https://github.com/yifeng-shen/reservoir/actions/workflows/snapshot.yml)

</div>

---

## 这是什么

- **单一事实来源（SSOT）**：身份、习惯、偏好、决策、技能只在这里维护一份，所有 AI 复用。
- **纯 Markdown + YAML Frontmatter**：无需数据库、无需转换，任何模型都能直接读。
- **读写分离**：核心身份只读；AI 的新发现先写入 `memory/inbox.md`，由你定期「转正」。
- **可追溯、可回退**：所有改动都有提交记录，受保护分支禁止强推和删除，支持按文件/按提交回滚。

> 这是公开仓库：**不要**写入手机号、住址、身份证、公司机密、API Key 等敏感信息。
> 所有 `{{占位符}}` 都需要你（或你的 AI）填写后才会成为有效记忆。

## 公开层 / 私密层

本仓库是**公开层**，只放可公开的身份、协作规则与通用结论。  
战略、财务、人事、合作方等敏感内容放在**私有层** `reservoir-private`（需授权访问），不进入本仓库。

| 层 | 内容 | 访问方式 |
| --- | --- | --- |
| 公开层（本仓库） | 身份、沟通、通用偏好、可公开结论 | raw URL / GitHub API，免授权 |
| 私密层 | 战略、财务、人事、合作方、未公开项目 | 私有仓库，PAT / 本地克隆 |

> AI 规则：任务涉及敏感内容时，先提醒我切换到私密层，不要在公开层展开。
> 完整规则见 [`ai-integration.md`](ai-integration.md) 第 9 节。

## 30 秒开始

```bash
git clone https://github.com/yifeng-shen/reservoir.git
cd reservoir
./scripts/setup.sh          # 可选：安装本地 Git hooks、检查环境

# 1) 填写身份（最少填 identity/profile.md）
$EDITOR identity/profile.md

# 2) 校验 + 生成索引 + 提交推送
python3 scripts/validate.py
python3 scripts/build_index.py
./scripts/sync.sh "identity: 完成基础信息"
```

然后把下面这句话发给任意 AI，即可完成接入：

```text
请先读取 https://raw.githubusercontent.com/yifeng-shen/reservoir/main/AGENTS.md
以及 identity/、workflow/ 下的文件，了解我是谁、如何与我协作。
之后每次任务结束，按 AGENTS.md 的写入协议把新经验写入 memory/inbox.md。
```

## 目录导航

| 目录 | 放什么 | AI 权限 | 入口文件 |
| --- | --- | --- | --- |
| [`identity/`](identity/README.md) | 身份、职业、标签、人生目标 | 只读 | [profile.md](identity/profile.md) |
| [`workflow/`](workflow/README.md) | 工作习惯、工具、沟通风格、优先级 | 可编辑 | [communication.md](workflow/communication.md) |
| [`memory/`](memory/README.md) | 决策、经验、偏好、对话沉淀 | 追加 | [inbox.md](memory/inbox.md) |
| [`skills/`](skills/README.md) | 已掌握技能、学习计划、待提升 | 可编辑 | [mastered.md](skills/mastered.md) |
| [`archive/`](archive/README.md) | 历史项目、文档、已完成任务 | 追加 | [projects.md](archive/projects.md) |
| [`knowledge/`](knowledge/README.md) | 可公开的 OTA 运营知识、行业方法 | 可编辑 | [ota/platforms.md](knowledge/ota/platforms.md) |
| [`mcp/`](mcp/README.md) | 本地 MCP Server，给 Agent 提供读写工具 | 代码 | [server.py](mcp/server.py) |
| [`integrations/`](integrations/) | ChatGPT Actions 等平台适配配置 | 只读 | [openai-actions.openapi.yaml](integrations/openai-actions.openapi.yaml) |

## AI 的四个读取入口

| 方式 | 地址 | 适用 |
| --- | --- | --- |
| 仓库根说明 | `https://raw.githubusercontent.com/yifeng-shen/reservoir/main/AGENTS.md` | 所有支持联网/读文件的 AI |
| LLM 索引 | `https://raw.githubusercontent.com/yifeng-shen/reservoir/main/llms.txt` | 按 llms.txt 规范抓取的模型 |
| 机器索引 | `https://raw.githubusercontent.com/yifeng-shen/reservoir/main/index.json` | 需要结构化文件清单的 Agent |
| GitHub API | `GET /repos/yifeng-shen/reservoir/contents/{path}` | ChatGPT Actions、自建 Agent |

本地 Agent（Claude Code、Cursor、Codex 等）直接 `git clone` 后读取即可；
需要「写回」能力时，接入 [`mcp/server.py`](mcp/server.py)。

## 读写权限标签

每个文件 H1 标题都以标签开头，AI 应先解析标签再决定能不能写：

| 标签 | 含义 | 涉及目录 |
| --- | --- | --- |
| `AI-READONLY` | 只读。AI 只能引用，不能改写；需要更正时写入 `memory/inbox.md` | `identity/`、根文档、`schema/` |
| `AI-APPEND` | 只能在文末「追加区」追加新条目，不得修改或删除历史条目 | `memory/`、`archive/` |
| `AI-EDIT` | 可在保留原意的前提下更新，须在变更记录中登记 | `workflow/`、`skills/` |
| `AI-GENERATED` | 机器生成，禁止手改 | `index.json`、`dist/` |

完整协议见 [AGENTS.md](AGENTS.md) 与 [ai-integration.md](ai-integration.md)。

## 版本保护与回退

- `main` 分支开启 Ruleset：**禁止删除、禁止强推、要求线性历史**。
- `snapshot/*` 标签受保护，每天由 GitHub Actions 自动打快照。
- 一键查看/回退：

```bash
./scripts/rollback.sh list              # 查看历史快照与提交
./scripts/rollback.sh show <commit>     # 查看某次提交改了什么
./scripts/rollback.sh restore <commit> identity/profile.md   # 恢复单个文件
./scripts/rollback.sh revert <commit>   # 生成一个反向提交（推荐）
```

## 常用脚本

| 脚本 | 作用 |
| --- | --- |
| [`scripts/setup.sh`](scripts/setup.sh) | 安装 Git hooks、检查 Python 环境 |
| [`scripts/validate.py`](scripts/validate.py) | 校验结构、标签、占位符与敏感信息 |
| [`scripts/build_index.py`](scripts/build_index.py) | 生成 `index.json` |
| [`scripts/sync.sh`](scripts/sync.sh) | 校验 → 重建索引 → 提交 → 变基 → 推送 |
| [`scripts/snapshot.sh`](scripts/snapshot.sh) | 创建并推送 `snapshot/*` 标签 |
| [`scripts/rollback.sh`](scripts/rollback.sh) | 查看历史、恢复单文件、生成反向提交 |
| [`scripts/watch.sh`](scripts/watch.sh) | 监听本地修改并自动同步（需 `fswatch`） |
| [`scripts/export_snapshot.sh`](scripts/export_snapshot.sh) | 导出单文件快照，给只支持知识库的平台 |
| [`scripts/github_protect.sh`](scripts/github_protect.sh) | 重新应用分支/标签保护与 Secret Scanning |

## 每周 10 分钟维护

1. 打开 [`memory/inbox.md`](memory/inbox.md)，把 AI 这一周写下的条目分流到 `decisions.md` / `preferences.md` / `experiences.md`。
2. 删除已转正的 inbox 条目，保留最近 30 天。
3. 更新 `identity/goals.md` 的进度，`skills/learning-plan.md` 的里程碑。
4. `./scripts/sync.sh "chore: 每周整理"`，然后 `./scripts/snapshot.sh weekly`。

## 隐私提醒

本仓库是 **Public**。公开个人档案的收益是任何 AI 都能免授权读取；代价是信息全网可见。
请只写「愿意公开的职业画像」，敏感信息留在本地或私有仓库。
仓库已开启 Secret Scanning 与 Push Protection，但仍需你自己把关。

## License

代码（`scripts/`、`mcp/`、`.github/`）采用 [MIT](LICENSE)；文字内容采用 [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)。
