# integrations/ · 平台适配配置

这里存放各 AI 平台的即用配置，目前包含 ChatGPT Custom GPT Actions。

## ChatGPT Custom GPT

1. 打开 <https://chatgpt.com/gpts/editor>，新建 GPT。
2. 在 **Configure → Actions** 中点击 **Create new action**。
3. 把 [`openai-actions.openapi.yaml`](openai-actions.openapi.yaml) 的内容粘贴进 Schema。
4. 认证选择 **None**（公开仓库，只读 raw 接口，无需 Token）。
5. 在 Instructions 中粘贴下面这段：

```text
你是我的个人助理。开始任务前，先调用 getIdentityProfile、getCommunicationStyle、
getPriorities 读取我的档案，然后严格按其中的沟通风格和权限规则工作。

规则：
- 不要复述档案内容，直接应用。
- 引用档案时标注来源文件，例如「来源：identity/profile.md」。
- 需要更多背景时调用 getDecisions / getPreferences / getFileIndex。
- 任务结束后，按 AGENTS.md 的格式输出 1–3 条记忆条目（Markdown 代码块），
  由我手动写入 memory/inbox.md。不要声称你已经写入。
```

6. 保存后，在对话里问「我是谁」验证是否能读取。

## 说明

- raw 接口有 CDN 缓存，更新后最多约 5 分钟生效；需要立即生效时加 `?t=<timestamp>`（本配置未加）。
- 只读接口不消耗 GitHub API 配额。
- 如果需要「写回」，请改用 [`../mcp/server.py`](../mcp/server.py)，不要让 GPT 持有写权限 Token。
