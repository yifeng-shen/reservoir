#!/usr/bin/env bash
# 安装 Git hooks 并做本地环境检查。
set -euo pipefail

cd "$(dirname "$0")/.."

echo "→ 配置 Git hooks（提交前自动校验）…"
git config core.hooksPath .githooks
chmod +x .githooks/* scripts/*.sh 2>/dev/null || true
echo "  ✓ core.hooksPath = .githooks"

echo "→ 检查 Python…"
python3 --version
python3 -c 'import sys; assert sys.version_info >= (3, 8), "需要 Python 3.8+"'
echo "  ✓ Python 可用"

if command -v fswatch >/dev/null 2>&1; then
  echo "  ✓ fswatch 已安装，可使用 ./scripts/watch.sh"
else
  echo "  ⚠ 未安装 fswatch；需要自动监听时运行：brew install fswatch"
fi

echo
echo "✓ 初始化完成。下一步："
echo "  1. 编辑 identity/profile.md"
echo "  2. python3 scripts/validate.py"
echo "  3. ./scripts/sync.sh \"identity: 完成基础信息\""
