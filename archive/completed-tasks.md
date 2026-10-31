---
schema: reservoir/v1
id: archive/completed-tasks
ai_tag: AI-APPEND
owner: yifeng-shen
created: "2026-10-31"
updated: "2026-10-31"
version: 1
tags:
  - archive
  - tasks
summary: "已完成任务流水与阶段总结"
---

# AI-APPEND: 已完成任务归档

> **给 AI 的指令**：这里记录已完成的任务，用于回答「我上次做到哪了」。
> 只追加。任务流水保持一行一条，阶段总结可以稍长。

## 使用方式

- 日常完成的任务：直接在「追加区」加一行。
- 每月/每季度：写一段阶段总结，链接到相关项目与决策。
- 与 `memory/decisions.md` 的区别：这里记「做了什么」，那里记「为什么这么选」。

## 任务流水模板

```markdown
- YYYY-MM-DD · {{任务}} · {{项目}} · {{结果}} · {{耗时}}
```

## 阶段总结模板

```markdown
### YYYY-MM · 月度总结
- **完成的重点**：…
- **未完成/延期**：…，原因 …
- **下月重点**：…
- **需要记住的教训**：…（同步到 memory/experiences.md）
```

---

## 追加区

<!-- 新完成任务从这一行下方追加。 -->
