#!/usr/bin/env bash
# 历史查看与回退。所有操作都不会 force push。
# 用法：
#   ./scripts/rollback.sh list
#   ./scripts/rollback.sh show <ref>
#   ./scripts/rollback.sh diff <ref> [path]
#   ./scripts/rollback.sh restore <ref> <path>     # 恢复单个文件到某版本
#   ./scripts/rollback.sh revert <ref>             # 生成反向提交（推荐）
set -euo pipefail

cd "$(dirname "$0")/.."

usage() {
  sed -n '2,12p' "$0"
  exit 1
}

cmd="${1:-list}"
shift || true

case "$cmd" in
  list)
    echo "最近 20 次提交："
    git log --oneline --decorate -20
    echo
    echo "快照标签："
    git tag -l 'snapshot/*' --sort=-creatordate | head -20
    ;;
  show)
    [ $# -ge 1 ] || usage
    git show --stat --oneline "$1"
    ;;
  diff)
    [ $# -ge 1 ] || usage
    ref="$1"; shift
    git diff "$ref" -- "${1:-.}"
    ;;
  restore)
    [ $# -ge 2 ] || usage
    ref="$1"; path="$2"
    git cat-file -e "${ref}:${path}" 2>/dev/null || {
      echo "✗ ${ref} 中不存在 ${path}" >&2
      exit 1
    }
    echo "即将把 ${path} 恢复到 ${ref} 的版本。"
    read -r -p "确认？[y/N] " ans
    [ "$ans" = "y" ] || [ "$ans" = "Y" ] || { echo "已取消"; exit 0; }
    git show "${ref}:${path}" > "$path"
    git add "$path"
    echo "✓ 已恢复 ${path}。检查后运行：git commit -m 'rollback: 恢复 ${path}'"
    ;;
  revert)
    [ $# -ge 1 ] || usage
    ref="$1"
    echo "将为 ${ref} 生成一个反向提交（不修改历史）。"
    read -r -p "确认？[y/N] " ans
    [ "$ans" = "y" ] || [ "$ans" = "Y" ] || { echo "已取消"; exit 0; }
    if git rev-parse -q --verify "${ref}^2" >/dev/null; then
      git revert --no-edit -m 1 "$ref"
    else
      git revert --no-edit "$ref"
    fi
    echo "✓ 已生成反向提交。推送请运行：git push origin main"
    ;;
  *)
    usage
    ;;
esac
