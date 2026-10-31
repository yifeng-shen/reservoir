# CLAUDE.md

本仓库是 @yifeng-shen 的个人记忆系统（Reservoir）。

完整的协作契约、读写权限、记忆条目格式与提交规范，全部在：

@AGENTS.md

补充：

- 只读目录：`identity/`、根文档、`schema/`
- 仅追加：`memory/`、`archive/`（追加到 `## 追加区`）
- 可编辑：`workflow/`、`skills/`
- 每次任务结束，按 `AGENTS.md` 第 4 节把新发现写入 `memory/inbox.md`
- 不要执行 `git push --force`、`git reset --hard`，不要删除分支或标签
- 引用档案时注明文件路径，例如 `identity/profile.md`

平台接入细节见 `ai-integration.md`；MCP 工具见 `mcp/server.py`。
