#!/usr/bin/env bash
# 把整个仓库导出为单文件快照，供「只支持上传知识库」的 AI 平台使用。
# 输出：dist/reservoir-snapshot.md（已被 .gitignore 忽略，不会提交）
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p dist

OUT="dist/reservoir-snapshot.md"
STAMP="$(date '+%Y-%m-%d %H:%M %Z')"

{
  echo "# Reservoir Snapshot"
  echo
  echo "> 生成时间：${STAMP}"
  echo "> 来源：https://github.com/yifeng-shen/reservoir"
  echo "> 用途：上传到仅支持知识库的 AI 平台。完整版请直接读 GitHub 仓库。"
  echo
  echo "---"
  echo

  for f in README.md AGENTS.md ai-integration.md \
           identity/profile.md identity/career.md identity/tags.md identity/goals.md \
           workflow/communication.md workflow/priorities.md workflow/tools.md workflow/habits.md \
           memory/preferences.md memory/decisions.md memory/experiences.md \
           skills/mastered.md skills/learning-plan.md skills/backlog.md \
           archive/projects.md; do
    [ -f "$f" ] || continue
    echo "<!-- ===== ${f} ===== -->"
    echo
    echo "## ${f}"
    echo
    cat "$f"
    echo
    echo "---"
    echo
  done
} > "$OUT"

BYTES="$(wc -c < "$OUT" | tr -d ' ')"
echo "✓ 已生成 ${OUT}（${BYTES} bytes）"
echo "  上传到 ChatGPT / Claude / Gemini 的知识库即可。"
