#!/usr/bin/env python3
"""校验 Reservoir 档案的结构、标签、占位符与敏感信息。

用法：
    python3 scripts/validate.py            # 检查，占位符仅警告
    python3 scripts/validate.py --strict   # 占位符未填完则失败（填完档案后建议开启）
    python3 scripts/validate.py --json     # 机器可读输出

退出码：0 = 通过，1 = 有错误（或 strict 模式下仍有占位符）。
"""

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOC_DIRS = ("identity", "workflow", "memory", "skills", "archive")
VALID_TAGS = {"AI-READONLY", "AI-APPEND", "AI-EDIT", "AI-GENERATED"}
REQUIRED_KEYS = ("schema", "id", "ai_tag", "updated")
PLACEHOLDER_RE = re.compile(r"\{\{([^{}]+)\}\}")
H1_RE = re.compile(r"^#\s+(.+?)\s*$", re.MULTILINE)

SECRET_PATTERNS = [
    ("GitHub Token", re.compile(r"\b(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})\b")),
    ("OpenAI Key", re.compile(r"\bsk-[A-Za-z0-9]{20,}\b")),
    ("AWS Access Key", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("Slack Token", re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{10,}\b")),
    ("Private Key", re.compile(r"-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----")),
    ("Bearer Token", re.compile(r"(?i)\bBearer\s+[A-Za-z0-9._\-]{30,}\b")),
]

SKIP_DIRS = {".git", "dist", ".tools", ".venv", "__pycache__", "node_modules", ".ai-cache"}
SCAN_SUFFIXES = {".md", ".json", ".yml", ".yaml", ".py", ".sh", ".txt"}


def parse_frontmatter(text):
    """返回 (dict, body)。没有 frontmatter 时返回 ({}, text)。"""
    if not text.startswith("---\n"):
        return {}, text
    end = text.find("\n---", 4)
    if end == -1:
        return {}, text
    raw = text[4:end]
    data = {}
    for line in raw.splitlines():
        line = line.rstrip()
        if not line or line.startswith("#") or line.startswith(" ") or line.startswith("- "):
            continue
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        data[key.strip()] = value.strip().strip('"').strip("'")
    return data, text[end + 4:]


def iter_content_files():
    for d in DOC_DIRS:
        base = ROOT / d
        if not base.exists():
            continue
        for path in sorted(base.glob("*.md")):
            if path.name != "README.md":
                yield path


def iter_scan_files():
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        if path.suffix.lower() in SCAN_SUFFIXES:
            yield path


def validate(strict=False):
    errors = []
    warnings = []
    files = []
    tag_counts = {}
    total_placeholders = 0

    for path in iter_content_files():
        rel = path.relative_to(ROOT).as_posix()
        text = path.read_text(encoding="utf-8")
        fm, body = parse_frontmatter(text)

        if not fm:
            errors.append("%s: 缺少 YAML Frontmatter" % rel)
            continue

        for key in REQUIRED_KEYS:
            if not fm.get(key):
                errors.append("%s: frontmatter 缺少字段 `%s`" % (rel, key))

        tag = fm.get("ai_tag", "")
        if tag and tag not in VALID_TAGS:
            errors.append("%s: 非法 ai_tag `%s`（允许：%s）" % (rel, tag, ", ".join(sorted(VALID_TAGS))))
        if tag:
            tag_counts[tag] = tag_counts.get(tag, 0) + 1

        expected_id = rel[:-3]
        if fm.get("id") and fm.get("id") != expected_id:
            errors.append("%s: id 应为 `%s`，实际为 `%s`" % (rel, expected_id, fm.get("id")))

        h1 = H1_RE.search(body)
        if not h1:
            errors.append("%s: 缺少 H1 标题" % rel)
        elif tag and not h1.group(1).startswith(tag + ":"):
            errors.append("%s: H1 应以 `# %s: ` 开头，实际为 `# %s`" % (rel, tag, h1.group(1)))

        if tag == "AI-APPEND" and "## 追加区" not in body:
            errors.append("%s: AI-APPEND 文件缺少 `## 追加区` 小节" % rel)

        placeholders = PLACEHOLDER_RE.findall(text)
        total_placeholders += len(placeholders)
        if placeholders:
            warnings.append("%s: 还有 %d 个占位符（如 %s）" % (rel, len(placeholders), placeholders[0]))

        files.append({
            "path": rel,
            "id": fm.get("id", ""),
            "ai_tag": tag,
            "placeholders": len(placeholders),
        })

    secret_hits = []
    for path in iter_scan_files():
        rel = path.relative_to(ROOT).as_posix()
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        for lineno, line in enumerate(text.splitlines(), 1):
            for name, pattern in SECRET_PATTERNS:
                if pattern.search(line):
                    secret_hits.append({"path": rel, "line": lineno, "type": name})
    for hit in secret_hits:
        errors.append("%s:%d 疑似泄露 %s（已阻止，请移除）" % (hit["path"], hit["line"], hit["type"]))

    if strict and total_placeholders:
        errors.append("strict 模式：仍有 %d 个占位符未填写" % total_placeholders)

    return {
        "ok": not errors,
        "strict": strict,
        "files": files,
        "file_count": len(files),
        "tag_counts": tag_counts,
        "placeholders": total_placeholders,
        "errors": errors,
        "warnings": warnings,
    }


def main():
    parser = argparse.ArgumentParser(description="校验 Reservoir 档案")
    parser.add_argument("--strict", action="store_true", help="占位符未填完时失败")
    parser.add_argument("--json", action="store_true", help="输出 JSON")
    args = parser.parse_args()

    result = validate(strict=args.strict)

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print("Reservoir 校验")
        print("  文件：%d 个 %s" % (result["file_count"], result["tag_counts"]))
        print("  占位符：%d 个" % result["placeholders"])
        if result["warnings"]:
            print("\n提示：")
            for item in result["warnings"]:
                print("  ⚠ %s" % item)
        if result["errors"]:
            print("\n错误：")
            for item in result["errors"]:
                print("  ✗ %s" % item)
        else:
            print("\n✓ 结构校验通过")

    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
