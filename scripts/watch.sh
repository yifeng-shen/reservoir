#!/usr/bin/env bash
# 监听本地修改，自动提交（默认不推送）。需要 fswatch：
#   macOS：brew install fswatch（或使用工作区内的 .tools/bin/fswatch）
#   Linux：apt install fswatch
# 用法：
#   ./scripts/watch.sh [提交信息前缀]
#   WATCH_PUSH=1 ./scripts/watch.sh    # 同时自动推送（需已配置凭据）
set -euo pipefail

cd "$(dirname "$0")/.."

export RESERVOIR_PUSH="${WATCH_PUSH:-0}"

FSWATCH_BIN="${FSWATCH_BIN:-}"
if [ -z "$FSWATCH_BIN" ]; then
  if command -v fswatch >/dev/null 2>&1; then
    FSWATCH_BIN="$(command -v fswatch)"
  elif [ -x "$PWD/.tools/bin/fswatch" ]; then
    FSWATCH_BIN="$PWD/.tools/bin/fswatch"
  else
    echo "✗ 未安装 fswatch。macOS：brew install fswatch；Linux：apt install fswatch" >&2
    echo "  或把可执行文件放到 .tools/bin/fswatch" >&2
    exit 1
  fi
fi

PREFIX="${1:-chore(watch)}"
echo "监听中…（Ctrl+C 停止；自动推送：$([ "$RESERVOIR_PUSH" = "1" ] && echo 开 || echo 关)）"

"$FSWATCH_BIN" -o -l 2 \
  identity workflow memory skills archive \
  README.md AGENTS.md CLAUDE.md ai-integration.md llms.txt index.json \
  | while read -r _; do
      if [ -n "$(git status --porcelain)" ]; then
        echo "[$(date '+%H:%M:%S')] 检测到修改，提交中…"
        ./scripts/sync.sh "${PREFIX}: $(date '+%Y-%m-%d %H:%M:%S')" || echo "⚠ 同步失败，请手动处理"
      fi
    done
