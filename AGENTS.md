# AGENTS.md · Reservoir 协作契约

> 本文件是**所有 AI / Agent 进入本仓库的第一入口**。开始任何任务前先读完本文件。
> 仓库地址：<https://github.com/yifeng-shen/reservoir>
> 维护者：[@yifeng-shen](https://github.com/yifeng-shen)

## 1. 这个仓库是什么

`reservoir` 是维护者的个人记忆系统，也是你（AI）了解他的**唯一事实来源**。
它不存放代码项目，只存放关于「人」的结构化 Markdown。

优先级从高到低：

1. `identity/` —— 他是谁（事实，只读）
2. `workflow/` —— 他怎么工作、怎么沟通（可编辑）
3. `memory/` —— 他做过什么决定、踩过什么坑、偏好什么（追加）
4. `skills/` —— 他会什么、在学什么（可编辑）
5. `archive/` —— 历史项目与文档（追加）

## 2. 读取顺序

处理任务前，按需读取，不要一次性灌入全部文件：

1. `identity/profile.md` + `identity/tags.md`（约 2 KB，必读）
2. `workflow/communication.md` + `workflow/priorities.md`（必读）
3. 与任务相关的 `workflow/tools.md`、`skills/mastered.md`
4. 需要历史上下文时：`memory/preferences.md` → `memory/decisions.md` → `memory/experiences.md`
5. 需要项目背景时：`archive/projects.md`

线上读取用 raw 地址：

```text
https://raw.githubusercontent.com/yifeng-shen/reservoir/main/<path>
```

## 3. 写入权限（硬约束）

| 标签 | 目录/文件 | 你能否写入 | 规则 |
| --- | --- | --- | --- |
| `AI-READONLY` | `identity/**`、`README.md`、`AGENTS.md`、`schema/**` | ❌ 禁止 | 发现错误只能写入 `memory/inbox.md` 并注明「建议更正 identity/xxx」 |
| `AI-APPEND` | `memory/**`、`archive/**` | ✅ 仅追加 | 只能插入到文末 `## 追加区` 之下，**不得修改、重排、删除任何已有内容** |
| `AI-EDIT` | `workflow/**`、`skills/**` | ✅ 可编辑 | 保留原意；同步更新 frontmatter 的 `updated` 与文末「变更记录」 |
| `AI-GENERATED` | `index.json`、`dist/**` | ❌ 禁止 | 由脚本生成 |

禁止行为：

- 禁止 `git push --force`、`git reset --hard`、删除分支/标签、改写历史。
- 禁止批量重写文件（一次提交不超过 5 个文件、300 行）。
- 禁止写入密钥、Token、密码、身份证号、住址、他人隐私。
- 禁止把推测写成事实；不确定的内容标 `置信度: 低`。
- 禁止把财务、人事、合作方、未公开战略等敏感内容写入本仓库；这些属于私密层 `reservoir-private`。
- 发现任务涉及上述内容时，先提醒维护者切换到私密层，不要在公开层继续展开。

## 4. 写入协议（任务结束后）

1. **先查重**：在 `memory/` 中搜索同主题条目，避免重复。
2. **写 inbox**：把新经验追加到 `memory/inbox.md` 的 `## 追加区`，使用第 5 节的条目格式。
3. **必要时更新**：
   - 沟通偏好变化 → `memory/preferences.md`（追加）
   - 工具/习惯变化 → `workflow/tools.md`、`workflow/habits.md`（编辑）
   - 技能进展 → `skills/mastered.md`、`skills/learning-plan.md`（编辑）
4. **提交**（如果具备写权限）：

```bash
git add -A
git commit -m "memory(auto): <一句话摘要> [ai:<你的名字>]"
git push origin main
```

5. **报告**：在回复末尾用一行说明写入了哪些文件，例如
   `📝 已记录：memory/inbox.md（2 条）`。

没有写权限时，把建议条目作为代码块输出，让维护者手动粘贴。

## 5. 记忆条目格式

```markdown
### YYYY-MM-DD · {{标题}}
- **场景**：{{在什么任务/对话中发生}}
- **结论**：{{可复用的事实、偏好或决策}}
- **原因**：{{为什么，背后的原则}}
- **边界**：{{什么情况下不适用}}
- **来源**：{{ChatGPT / Claude / Gemini / Cursor / 人工}}
- **置信度**：高 / 中 / 低
```

好条目的标准：**可复用、可验证、有边界**。
反例：「用户喜欢简洁」——太泛。正例：「代码 review 场景下，先给结论再给 diff，不超过 10 行」。

## 6. 沟通约定

- 默认中文，技术术语保留英文。
- 先结论后论据；不确定时明确说「不确定」，不要编造。
- 引用本仓库内容时注明文件路径，例如 `identity/profile.md`。
- 涉及身份事实的改动，必须先征求维护者确认。

## 7. 自检清单

- [ ] 我读的是最新 `main` 分支吗？
- [ ] 我有没有修改只读文件？
- [ ] 新条目是否包含来源与置信度？
- [ ] 提交信息是否符合 `type(scope): summary [ai:name]`？
- [ ] 有没有泄露任何敏感信息？

---

_本文件由维护者维护，AI 不得修改。协议版本：v1（2026-10-31）。_
