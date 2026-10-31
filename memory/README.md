# memory/ · 记忆沉淀层

> **AI 权限：`AI-APPEND`**。这里写「我经历过什么、因此形成了什么偏好」。
> AI 只能追加，不能修改或删除历史。所有新内容先进 [`inbox.md`](inbox.md)，由我定期转正。

## 文件说明

| 文件 | 内容 | 谁来写 |
| --- | --- | --- |
| [`inbox.md`](inbox.md) | AI 的原始观察与建议，待人工筛选 | AI 追加 |
| [`decisions.md`](decisions.md) | 重要决策：背景、选项、理由、结果 | AI + 人工 |
| [`experiences.md`](experiences.md) | 可复用的经验与踩坑教训 | AI + 人工 |
| [`preferences.md`](preferences.md) | 已被验证的协作偏好 | AI + 人工 |

## 为什么要有 inbox

AI 很容易把「一次偶然」写成「永久偏好」。直接改正式文件会污染记忆。
所以采用**两段式**：

```text
AI 任务结束
   └─> memory/inbox.md 追加条目（带来源、置信度）
          └─> 你每周筛选
                 ├─> 高置信 + 可复用 → decisions.md / preferences.md / experiences.md
                 ├─> 需要观察 → 留在 inbox
                 └─> 一次性 → 删除
```

## 条目格式

```markdown
### YYYY-MM-DD · 标题
- **场景**：在什么任务/对话中发生
- **结论**：可复用的事实、偏好或决策
- **原因**：为什么，背后的原则
- **边界**：什么情况下不适用
- **来源**：ChatGPT / Claude / Gemini / Cursor / 人工
- **置信度**：高 / 中 / 低
```

## 转正规则

- **至少出现 2 次**，或来源可靠且边界清晰，才能进入 `preferences.md`。
- 决策类进入 `decisions.md`，必须补上「结果复盘」栏，哪怕写「待观察」。
- 转正后从 inbox 删除，并在目标文件的「变更记录」登记。
- 每月清理一次 inbox，超过 60 天未处理的条目直接归档到 `archive/completed-tasks.md` 或删除。

## 不要写

- 密码、Token、身份证、住址、他人隐私。
- 未公开的公司业务数据。
- 情绪化的吐槽（可以写「当时很沮丧」，但结论要客观）。
