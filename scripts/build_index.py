#!/usr/bin/env python3
"""生成 index.json：给 AI 的机器可读文件清单。

用法：
    python3 scripts/build_index.py           # 重新生成
    python3 scripts/build_index.py --check   # 只检查是否最新（CI 用）
"""

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "index.json"
DOC_DIRS = ("identity", "workflow", "memory", "skills", "archive")
ROOT_DOCS = ("README.md", "AGENTS.md", "CLAUDE.md", "ai-integration.md", "llms.txt")
RAW_BASE = "https://raw.githubusercontent.com/yifeng-shen/reservoir/main/"
REPO_URL = "https://github.com/yifeng-shen/reservoir"
PLACEHOLDER_RE = re.compile(r"\{\{[^{}]+\}\}")
H1_RE = re.compile(r"^#\s+(.+?)\s*$", re.MULTILINE)


def parse_frontmatter(text):
    if not text.startswith("---\n"):
        return {}, text
    end = text.find("\n---", 4)
    if end == -1:
        return {}, text
    data = {}
    for line in text[4:end].splitlines():
        if not line or line.startswith(" ") or line.startswith("- ") or ":" not in line:
            continue
        key, value = line.split(":", 1)
        data[key.strip()] = value.strip().strip('"').strip("'")
    return data, text[end + 4:]


def entry_for(path):
    rel = path.relative_to(ROOT).as_posix()
    text = path.read_text(encoding="utf-8")
    fm, body = parse_frontmatter(text)
    h1 = H1_RE.search(body)
    title = h1.group(1).strip() if h1 else path.stem
    if ":" in title and title.startswith("AI-"):
        title = title.split(":", 1)[1].strip()

    summary = fm.get("summary", "")
    if not summary:
        for line in body.splitlines():
            line = line.strip()
            if line.startswith(">") and not line.startswith("> **"):
                summary = line.lstrip("> ").strip()
                break

    return {
        "path": rel,
        "id": fm.get("id", rel[:-3] if rel.endswith(".md") else rel),
        "ai_tag": fm.get("ai_tag", "AI-READONLY"),
        "title": title,
        "summary": summary,
        "updated": fm.get("updated", ""),
        "tags": [t.strip() for t in fm.get("tags", "").strip("[]").split(",") if t.strip()],
        "bytes": len(text.encode("utf-8")),
        "sha256": hashlib.sha256(text.encode("utf-8")).hexdigest()[:16],
        "placeholders": len(PLACEHOLDER_RE.findall(text)),
        "raw_url": RAW_BASE + rel,
        "html_url": REPO_URL + "/blob/main/" + rel,
    }


def collect():
    files = []
    for name in ROOT_DOCS:
        path = ROOT / name
        if path.is_file():
            files.append(entry_for(path))
    for d in DOC_DIRS:
        base = ROOT / d
        if not base.exists():
            continue
        for path in sorted(base.glob("*.md")):
            files.append(entry_for(path))
    files.sort(key=lambda item: item["path"])
    payload = {
        "schema": "reservoir/index/v1",
        "repository": REPO_URL,
        "branch": "main",
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "counts": {
            "files": len(files),
            "placeholders": sum(item["placeholders"] for item in files),
        },
        "by_tag": {},
        "files": files,
    }
    for item in files:
        tag = item["ai_tag"]
        payload["by_tag"][tag] = payload["by_tag"].get(tag, 0) + 1
    return payload


def main():
    parser = argparse.ArgumentParser(description="生成 Reservoir index.json")
    parser.add_argument("--check", action="store_true", help="只检查 index.json 是否最新")
    args = parser.parse_args()

    payload = collect()

    if args.check:
        if not OUT.exists():
            print("✗ index.json 不存在，请运行 python3 scripts/build_index.py")
            return 1
        current = json.loads(OUT.read_text(encoding="utf-8"))
        if current.get("files") != payload["files"] or current.get("counts") != payload["counts"]:
            print("✗ index.json 已过期，请运行 python3 scripts/build_index.py 并提交")
            return 1
        print("✓ index.json 已是最新（%d 个文件）" % payload["counts"]["files"])
        return 0

    # 内容没变时保留原时间戳，避免每日快照产生空提交
    if OUT.exists():
        try:
            current = json.loads(OUT.read_text(encoding="utf-8"))
            if (current.get("files") == payload["files"]
                    and current.get("counts") == payload["counts"]
                    and current.get("generated_at")):
                payload["generated_at"] = current["generated_at"]
        except (OSError, ValueError):
            pass

    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("✓ 已生成 index.json：%d 个文件，%d 个占位符" % (
        payload["counts"]["files"], payload["counts"]["placeholders"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
