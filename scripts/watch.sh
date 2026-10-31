#!/usr/bin/env bash
# 监听本地修改，自动提交并推送。需要 fswatch：brew install fswatch
# 用法：./scripts/watch.sh [提交信息前缀]
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v fswatch >/dev/null 2>&1; then
  echo "✗ 未安装 fswatch。macOS：brew install fswatch；Linux：apt install fswatch" >&2
  exit 1
fi

PREFIX="${1:-chore(watch)}"
echo "监听中…（Ctrl+C 停止）"

fswatch -o -l 2 \
  identity workflow memory skills archive \
  README.md AGENTS.md CLAUDE.md ai-integration.md llms.txt index.json \
  | while read -r _; do
      if [ -n "$(git status --porcelain)" ]; then
        echo "[$(date '+%H:%M:%S')] 检测到修改，同步中…"
        ./scripts/sync.sh "${PREFIX}: $(date '+%Y-%m-%d %H:%M:%S')" || echo "⚠ 同步失败，请手动处理"
      fi
    done
