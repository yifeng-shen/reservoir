# mcp/ · Reservoir MCP Server

一个零依赖的 [Model Context Protocol](https://modelcontextprotocol.io) Server，
让 Claude Desktop、Cursor、Cline 等客户端直接读写本地 `reservoir` 克隆。

## 能力

| 工具 | 作用 | 权限 |
| --- | --- | --- |
| `reservoir_read` | 读取指定档案文件 | 只读 |
| `reservoir_search` | 在五个目录中全文搜索 | 只读 |
| `reservoir_append` | 追加记忆到 `memory/inbox.md` | 仅追加 |
| `reservoir_log_decision` | 追加决策到 `memory/decisions.md` | 仅追加 |

写操作只追加，且强制要求 `## 追加区` 存在；不会修改或删除任何历史内容。

## 安装

无需安装依赖，Python 3.8+ 即可：

```bash
python3 --version
RESERVOIR_ROOT="$HOME/.reservoir" python3 mcp/server.py
```

## 客户端配置

把 `/Users/syf/.reservoir` 换成你的克隆路径。

### Claude Desktop

编辑 `~/Library/Application Support/Claude/claude_desktop_config.json`：

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

### Cursor

`.cursor/mcp.json`：

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

### 其他客户端

任何支持 stdio MCP 的客户端都可以用上面的命令启动。协议版本 `2024-11-05`。

## 手动测试

```bash
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  | RESERVOIR_ROOT="$PWD" python3 mcp/server.py
```

## 安全边界

- 只能读 `identity/`、`workflow/`、`memory/`、`skills/`、`archive/` 与根目录白名单文档。
- 只能写 `memory/inbox.md` 与 `memory/decisions.md`，且只追加。
- 拒绝路径穿越（`../`）、`.git` 访问和超大文件。
- 不联网、不持有 Token；提交与推送仍由你或 Agent 的 git 流程完成。
