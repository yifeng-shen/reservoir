#!/usr/bin/env bash
# 一键提交并推送：校验 -> 重建索引 -> 提交 -> 变基 -> 推送
# 用法：./scripts/sync.sh "memory: 记录本周偏好"
set -euo pipefail

cd "$(dirname "$0")/.."

MSG="${1:-chore(sync): $(date '+%Y-%m-%d %H:%M')}"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "✗ 当前目录不是 Git 仓库" >&2
  exit 1
fi

echo "→ 校验档案…"
python3 scripts/validate.py

echo "→ 重建索引…"
python3 scripts/build_index.py

git add -A

if git diff --cached --quiet; then
  echo "✓ 没有需要提交的变更"
  exit 0
fi

echo "→ 提交：$MSG"
git commit -m "$MSG"

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if git remote get-url origin >/dev/null 2>&1; then
  echo "→ 同步远端 origin/$BRANCH…"
  git pull --rebase --autostash origin "$BRANCH"
  git push origin "$BRANCH"
  echo "✓ 已推送 origin/$BRANCH"
else
  echo "⚠ 未配置 origin，已本地提交但未推送"
fi
