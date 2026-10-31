---
schema: reservoir/v1
id: archive/documents
ai_tag: AI-APPEND
owner: yifeng-shen
created: "2026-10-31"
updated: "2026-10-31"
version: 1
tags:
  - archive
  - documents
summary: "重要文档与外部资料索引"
---

# AI-APPEND: 文档与资料索引

> **给 AI 的指令**：需要引用我的历史文档时，先看这张索引。
> 只追加。仓库不存放大文件，只存链接与摘要。

## 文档索引

| 日期 | 名称 | 类型 | 位置 | 摘要 |
| --- | --- | --- | --- | --- |
| {{YYYY-MM-DD}} | {{文档名}} | 方案 / 复盘 / 规范 / 笔记 | {{URL 或内部路径}} | {{一句话}} |

## 按主题

### 技术

- {{文档}} —— {{摘要}}

### 产品 / 业务

- {{文档}} —— {{摘要}}

### 个人成长

- {{文档}} —— {{摘要}}

## 外部资料

| 名称 | 类型 | 链接 | 为什么收藏 |
| --- | --- | --- | --- |
| {{…}} | 文章 / 课程 / 工具 | {{URL}} | {{…}} |

## 存放约定

- 可公开的文档：放 `archive/files/`，命名 `YYYY-MM-DD-主题.md`。
- 不可公开的：只写标题 + 「见内部知识库」，不要放链接。
- 大文件（PDF、图片）：放对象存储，索引里留 URL。

---

## 追加区

<!-- 新文档从这一行下方追加。 -->

### 2026-11-01 · Reservoir 核心文档索引
- [README](../README.md) —— 使用说明、目录导航、维护节奏
- [AGENTS.md](../AGENTS.md) —— AI 协作契约、读写权限、记忆条目格式
- [ai-integration.md](../ai-integration.md) —— ChatGPT / Claude / Gemini / Agent 平台接入配置
- [integrations/openai-actions.openapi.yaml](../integrations/openai-actions.openapi.yaml) —— ChatGPT Custom GPT Actions 配置
- [mcp/server.py](../mcp/server.py) —— 本地 MCP Server，提供读 / 搜 / 追加 / 记决策工具
- [scripts/rollback.sh](../scripts/rollback.sh) —— 历史查看与回退
- [index.json](../index.json) —— 机器可读文件清单
