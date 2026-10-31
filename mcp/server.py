#!/usr/bin/env python3
"""Reservoir MCP Server — 给任意支持 MCP 的 AI 客户端提供读写工具。

零第三方依赖，仅使用 Python 标准库。传输方式：stdio，JSON-RPC 2.0，按行分隔。

环境变量：
    RESERVOIR_ROOT  仓库根目录（默认：本文件上一级目录）

工具：
    reservoir_read          读取档案文件（只读）
    reservoir_search        全文搜索（只读）
    reservoir_append        追加到 memory/inbox.md（仅追加）
    reservoir_log_decision  追加到 memory/decisions.md（仅追加）
"""

import json
import os
import sys
from datetime import date
from pathlib import Path

SERVER_NAME = "reservoir"
SERVER_VERSION = "1.1.0"
PROTOCOL_VERSION = "2024-11-05"

ROOT = Path(
    os.environ.get("RESERVOIR_ROOT") or Path(__file__).resolve().parent.parent
).resolve()

READABLE_DIRS = ("identity", "workflow", "memory", "skills", "archive", "knowledge")
READABLE_ROOT_FILES = ("README.md", "AGENTS.md", "CLAUDE.md", "ai-integration.md", "llms.txt", "index.json")
READABLE_SUFFIXES = (".md", ".json", ".txt", ".yaml", ".yml")

WRITE_TARGETS = {
    "inbox": "memory/inbox.md",
    "decisions": "memory/decisions.md",
}

MAX_READ_BYTES = 2_000_000
MAX_FIELD_CHARS = 8_000


def _within_root(path: Path) -> bool:
    try:
        path.relative_to(ROOT)
        return True
    except ValueError:
        return False


def _resolve_read(rel_path: str) -> Path:
    rel_path = (rel_path or "").strip().lstrip("/")
    if not rel_path:
        raise ValueError("path 不能为空")
    if rel_path.startswith(".git/") or "/.git/" in rel_path:
        raise ValueError("禁止访问 .git")
    path = (ROOT / rel_path).resolve()
    if not _within_root(path):
        raise ValueError("路径越界")
    if not path.is_file():
        raise ValueError("文件不存在: %s" % rel_path)
    if path.suffix.lower() not in READABLE_SUFFIXES:
        raise ValueError("不支持的文件类型: %s" % path.suffix)
    top = rel_path.split("/", 1)[0]
    if "/" in rel_path and top not in READABLE_DIRS:
        raise ValueError("只允许读取 identity/ workflow/ memory/ skills/ archive/ 及根目录文档")
    if "/" not in rel_path and rel_path not in READABLE_ROOT_FILES:
        raise ValueError("只允许读取根目录白名单文档")
    if path.stat().st_size > MAX_READ_BYTES:
        raise ValueError("文件过大")
    return path


def _snippet(text: str, query: str, radius: int = 80) -> str:
    idx = text.lower().find(query.lower())
    if idx < 0:
        return ""
    start = max(0, idx - radius)
    end = min(len(text), idx + len(query) + radius)
    snippet = text[start:end].replace("\n", " ").strip()
    return ("…" if start > 0 else "") + snippet + ("…" if end < len(text) else "")


def _iter_docs():
    for d in READABLE_DIRS:
        base = ROOT / d
        if not base.exists():
            continue
        for path in sorted(base.rglob("*.md")):
            if path.is_file() and path.stat().st_size <= MAX_READ_BYTES:
                yield path


def _append(target_key: str, block: str) -> str:
    rel = WRITE_TARGETS[target_key]
    path = (ROOT / rel).resolve()
    if not _within_root(path) or not path.is_file():
        raise ValueError("目标文件不存在: %s" % rel)
    text = path.read_text(encoding="utf-8")
    if "## 追加区" not in text:
        raise ValueError("%s 缺少「## 追加区」，拒绝写入" % rel)
    block = block.strip()
    if not block:
        raise ValueError("内容为空")
    # 纯追加：不改动任何已有字节
    with path.open("a", encoding="utf-8") as fh:
        if not text.endswith("\n"):
            fh.write("\n")
        fh.write("\n" + block + "\n")
    return rel


def tool_read(args):
    path = _resolve_read(args.get("path", ""))
    text = path.read_text(encoding="utf-8")
    return {"content": [{"type": "text", "text": text}], "isError": False}


def tool_search(args):
    query = (args.get("query") or "").strip()
    if len(query) < 2:
        raise ValueError("query 至少 2 个字符")
    limit = max(1, min(int(args.get("limit") or 20), 50))
    results = []
    for path in _iter_docs():
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        if query.lower() not in text.lower():
            continue
        rel = path.relative_to(ROOT).as_posix()
        for lineno, line in enumerate(text.splitlines(), 1):
            if query.lower() in line.lower():
                results.append({
                    "path": rel,
                    "line": lineno,
                    "text": line.strip()[:300],
                })
                if len(results) >= limit:
                    break
        if len(results) >= limit:
            break
    if not results:
        return {"content": [{"type": "text", "text": "未找到匹配: %s" % query}], "isError": False}
    lines = ["找到 %d 条匹配：" % len(results)]
    for r in results:
        lines.append("- %s:%d  %s" % (r["path"], r["line"], r["text"]))
    return {"content": [{"type": "text", "text": "\n".join(lines)}], "isError": False}


def _field(args, key, required=False):
    value = (args.get(key) or "").strip()
    if required and not value:
        raise ValueError("缺少字段: %s" % key)
    if len(value) > MAX_FIELD_CHARS:
        raise ValueError("字段过长: %s" % key)
    return value


def _confidence(args):
    value = (args.get("confidence") or "中").strip()
    if value not in ("高", "中", "低"):
        raise ValueError("confidence 必须是 高/中/低")
    return value


def tool_append(args):
    title = _field(args, "title", True)
    scenario = _field(args, "scenario", True)
    conclusion = _field(args, "conclusion", True)
    reason = _field(args, "reason") or "未提供"
    boundary = _field(args, "boundary") or "未提供"
    source = _field(args, "source") or "AI"
    confidence = _confidence(args)
    day = (args.get("date") or date.today().isoformat()).strip()[:10]

    block = (
        "### %s · %s\n"
        "- **场景**：%s\n"
        "- **结论**：%s\n"
        "- **原因**：%s\n"
        "- **边界**：%s\n"
        "- **来源**：%s\n"
        "- **置信度**：%s\n"
    ) % (day, title, scenario, conclusion, reason, boundary, source, confidence)
    rel = _append("inbox", block)
    return {
        "content": [{"type": "text", "text": "已追加到 %s：%s" % (rel, title)}],
        "isError": False,
    }


def tool_log_decision(args):
    title = _field(args, "title", True)
    background = _field(args, "background", True)
    options = _field(args, "options") or "未提供"
    decision = _field(args, "decision", True)
    reason = _field(args, "reason", True)
    expected = _field(args, "expected") or "待观察"
    source = _field(args, "source") or "AI"
    day = (args.get("date") or date.today().isoformat()).strip()[:10]

    block = (
        "### %s · %s\n"
        "- **背景**：%s\n"
        "- **选项**：%s\n"
        "- **决定**：%s\n"
        "- **理由**：%s\n"
        "- **预期结果**：%s\n"
        "- **复盘**：待观察\n"
        "- **来源**：%s\n"
    ) % (day, title, background, options, decision, reason, expected, source)
    rel = _append("decisions", block)
    return {
        "content": [{"type": "text", "text": "已追加到 %s：%s" % (rel, title)}],
        "isError": False,
    }


TOOLS = [
    {
        "name": "reservoir_read",
        "description": "读取 Reservoir 个人档案文件。传入相对仓库根目录的路径，例如 identity/profile.md。",
        "inputSchema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "相对路径，如 identity/profile.md"}
            },
            "required": ["path"],
            "additionalProperties": False,
        },
    },
    {
        "name": "reservoir_search",
        "description": "在 identity/workflow/memory/skills/archive 中全文搜索个人记忆，返回文件、行号与片段。",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "搜索词，至少 2 个字符"},
                "limit": {"type": "integer", "minimum": 1, "maximum": 50, "default": 20},
            },
            "required": ["query"],
            "additionalProperties": False,
        },
    },
    {
        "name": "reservoir_append",
        "description": "把一条新记忆追加到 memory/inbox.md（仅追加，不修改历史）。任务结束时使用。",
        "inputSchema": {
            "type": "object",
            "properties": {
                "title": {"type": "string"},
                "scenario": {"type": "string", "description": "在什么任务/对话中发生"},
                "conclusion": {"type": "string", "description": "可复用的事实、偏好或结论"},
                "reason": {"type": "string"},
                "boundary": {"type": "string", "description": "什么情况下不适用"},
                "source": {"type": "string", "description": "如 ChatGPT / Claude / 人工"},
                "confidence": {"type": "string", "enum": ["高", "中", "低"]},
                "date": {"type": "string", "description": "YYYY-MM-DD，默认今天"},
            },
            "required": ["title", "scenario", "conclusion", "source"],
            "additionalProperties": False,
        },
    },
    {
        "name": "reservoir_log_decision",
        "description": "把一条重要决策追加到 memory/decisions.md（仅追加）。",
        "inputSchema": {
            "type": "object",
            "properties": {
                "title": {"type": "string"},
                "background": {"type": "string"},
                "options": {"type": "string", "description": "考虑过的选项与代价"},
                "decision": {"type": "string"},
                "reason": {"type": "string"},
                "expected": {"type": "string", "description": "预期结果"},
                "source": {"type": "string"},
                "date": {"type": "string"},
            },
            "required": ["title", "background", "decision", "reason"],
            "additionalProperties": False,
        },
    },
]

HANDLERS = {
    "reservoir_read": tool_read,
    "reservoir_search": tool_search,
    "reservoir_append": tool_append,
    "reservoir_log_decision": tool_log_decision,
}


def _send(payload):
    sys.stdout.write(json.dumps(payload, ensure_ascii=False) + "\n")
    sys.stdout.flush()


def _error(msg_id, code, message):
    _send({"jsonrpc": "2.0", "id": msg_id, "error": {"code": code, "message": message}})


def handle(msg):
    method = msg.get("method")
    msg_id = msg.get("id")
    params = msg.get("params") or {}

    if method == "initialize":
        return {
            "protocolVersion": PROTOCOL_VERSION,
            "capabilities": {"tools": {"listChanged": False}},
            "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
        }

    if method in ("notifications/initialized", "initialized"):
        return None

    if method == "ping":
        return {}

    if method == "tools/list":
        return {"tools": TOOLS}

    if method == "tools/call":
        name = params.get("name")
        args = params.get("arguments") or {}
        handler = HANDLERS.get(name)
        if handler is None:
            raise ValueError("未知工具: %s" % name)
        try:
            return handler(args)
        except Exception as exc:  # noqa: BLE001 - 返回给客户端而不是崩溃
            return {
                "content": [{"type": "text", "text": "工具执行失败: %s" % exc}],
                "isError": True,
            }

    raise LookupError("未知方法: %s" % method)


def main():
    for raw in sys.stdin:
        raw = raw.strip()
        if not raw:
            continue
        try:
            msg = json.loads(raw)
        except json.JSONDecodeError:
            _error(None, -32700, "Parse error")
            continue

        if not isinstance(msg, dict) or "id" not in msg:
            # 通知消息：处理但不回复
            continue

        try:
            result = handle(msg)
        except LookupError as exc:
            _error(msg["id"], -32601, str(exc))
            continue
        except Exception as exc:  # noqa: BLE001
            _error(msg["id"], -32603, str(exc))
            continue

        if result is None:
            continue
        _send({"jsonrpc": "2.0", "id": msg["id"], "result": result})


if __name__ == "__main__":
    main()
