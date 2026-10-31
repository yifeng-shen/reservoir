#!/usr/bin/env bash
# 创建并推送一个快照标签。用法：./scripts/snapshot.sh [标签后缀]
set -euo pipefail

cd "$(dirname "$0")/.."

LABEL="${1:-manual}"
STAMP="$(date '+%Y-%m-%d-%H%M')"
TAG="snapshot/${STAMP}-${LABEL}"

if [ -n "$(git status --porcelain)" ]; then
  echo "⚠ 工作区有未提交的修改，先运行 ./scripts/sync.sh 再打快照" >&2
  exit 1
fi

git tag -a "$TAG" -m "Reservoir snapshot ${STAMP} (${LABEL})"
echo "✓ 已创建标签 $TAG"

if git remote get-url origin >/dev/null 2>&1; then
  git push origin "$TAG"
  echo "✓ 已推送 $TAG"
else
  echo "⚠ 未配置 origin，标签仅存在于本地"
fi
