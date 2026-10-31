---
schema: reservoir/v1
id: archive/projects
ai_tag: AI-APPEND
owner: yifeng-shen
created: "2026-10-31"
updated: "2026-10-31"
version: 1
tags:
  - archive
  - projects
summary: "历史项目索引：背景、角色、结果、复盘"
---

# AI-APPEND: 历史项目归档

> **给 AI 的指令**：需要了解我的项目经验时读这里。只追加，不修改历史条目。
> 项目细节以「结果」和「复盘」为准，不要根据标题推测技术细节。

## 项目索引

| 年份 | 项目 | 角色 | 结果 | 关键词 |
| --- | --- | --- | --- | --- |
| {{2026}} | {{项目名}} | {{角色}} | {{一句话结果}} | {{…}} |
| {{2025}} | {{项目名}} | {{角色}} | {{一句话结果}} | {{…}} |

## 项目详情模板

```markdown
### YYYY · 项目名
- **背景**：为什么要做
- **我的角色**：负责什么，团队多大
- **做法**：关键技术/方法选择
- **结果**：可量化的产出
- **难点**：最难的一件事
- **复盘**：如果重来会怎么做
- **链接**：仓库 / 文档 / 演示（可公开的）
```

---

## 追加区

<!-- 新项目从这一行下方追加，最新的在上方。 -->

### 2026 · Reservoir 个人记忆系统
- **背景**：多个 AI 平台各自记忆，换设备或换模型就要重新解释自己
- **我的角色**：需求定义、内容审核与验收；AI 负责搭建、文档与自动化
- **做法**：GitHub 公开仓库；identity / workflow / memory / skills / archive 五目录；YAML frontmatter + AI 权限标签；inbox 两段式记忆；MCP Server + ChatGPT Actions；Ruleset + 每日快照
- **结果**：仓库上线，52 个受控文件；validate 与 snapshot 均通过；身份与沟通规则已入库
- **难点**：公开仓库的隐私边界；GitHub 网络与 OAuth 授权；AI 写回权限与令牌安全
- **复盘**：先跑通最小可用骨架，再逐目录补内容；不要一次追求全量
- **链接**：https://github.com/yifeng-shen/reservoir
