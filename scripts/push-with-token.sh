#!/usr/bin/env bash
# 用 Fine-grained PAT 推送公开层与私密层。
#
# 特点：
#   - token 只从环境变量或本地文件读取，不打印、不写入仓库、不写入 git config
#   - 用临时 askpass 传给 git，命令结束后删除
#   - 不 force push；有未提交改动时拒绝执行
#   - 自动读取 macOS 系统代理（HTTPS_PROXY 未设置时）
#
# 用法：
#   ./scripts/push-with-token.sh --save-token          # 交互式保存到 .tools/gh_token（600）
#   ./scripts/push-with-token.sh --check               # 只验证 token 与仓库权限
#   ./scripts/push-with-token.sh all                   # 推送公开层 + 私密层
#   ./scripts/push-with-token.sh public                # 只推公开层
#   ./scripts/push-with-token.sh private               # 只推私密层
#   ./scripts/push-with-token.sh --token-file ~/.reservoir-token all
#
# token 查找顺序：
#   1. $GH_TOKEN
#   2. --token-file 指定的文件
#   3. <repo>/.tools/gh_token
#   4. ~/.reservoir-token
#   5. ~/.config/reservoir/token
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRIVATE_REPO="${PRIVATE_REPO:-$ROOT/private/reservoir-private}"
OWNER="${OWNER:-yifeng-shen}"
API="https://api.github.com"

TARGET="all"
MODE="push"
TOKEN_FILE=""
TOKEN_SOURCE=""

usage() {
  sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE="check"; shift ;;
    --save-token) MODE="save"; shift ;;
    --token-file)
      TOKEN_FILE="${2:-}"
      [ -n "$TOKEN_FILE" ] || { echo "✗ --token-file 需要路径" >&2; exit 2; }
      shift 2
      ;;
    public|private|all) TARGET="$1"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "✗ 未知参数：$1" >&2; usage; exit 2 ;;
  esac
done

detect_proxy() {
  [ -n "${HTTPS_PROXY:-}" ] && return 0
  command -v scutil >/dev/null 2>&1 || return 0
  local host port
  host="$(scutil --proxy | awk '/HTTPSProxy/ {print $3; exit}')"
  port="$(scutil --proxy | awk '/HTTPSPort/ {print $3; exit}')"
  if [ -n "$host" ] && [ -n "$port" ]; then
    export HTTPS_PROXY="http://$host:$port"
    export HTTP_PROXY="$HTTPS_PROXY"
    export https_proxy="$HTTPS_PROXY"
    export http_proxy="$HTTPS_PROXY"
    echo "→ 使用系统代理 $HTTPS_PROXY"
  fi
}

find_token() {
  local candidate value
  if [ -n "${GH_TOKEN:-}" ]; then
    TOKEN="$GH_TOKEN"
    TOKEN_SOURCE="环境变量 GH_TOKEN"
    return 0
  fi
  for candidate in "$TOKEN_FILE" "$ROOT/.tools/gh_token" "$HOME/.reservoir-token" "$HOME/.config/reservoir/token"; do
    [ -n "$candidate" ] || continue
    if [ -f "$candidate" ]; then
      value="$(tr -d '[:space:]' < "$candidate")"
      if [ -n "$value" ]; then
        TOKEN="$value"
        TOKEN_SOURCE="$candidate"
        return 0
      fi
    fi
  done
  return 1
}

check_file_permissions() {
  [ -n "$TOKEN_SOURCE" ] || return 0
  case "$TOKEN_SOURCE" in
    环境变量*) return 0 ;;
  esac
  local mode
  mode="$(stat -f '%Lp' "$TOKEN_SOURCE" 2>/dev/null || stat -c '%a' "$TOKEN_SOURCE" 2>/dev/null || true)"
  if [ -n "$mode" ] && [ "$mode" != "600" ]; then
    echo "⚠ token 文件权限是 $mode，建议：chmod 600 \"$TOKEN_SOURCE\""
  fi
}

if [ "$MODE" = "save" ]; then
  mkdir -p "$ROOT/.tools"
  printf 'Paste Fine-grained PAT (input hidden): '
  IFS= read -r -s TOKEN
  echo
  [ -n "$TOKEN" ] || { echo "✗ 空 token，已取消" >&2; exit 1; }
  printf '%s' "$TOKEN" > "$ROOT/.tools/gh_token"
  chmod 600 "$ROOT/.tools/gh_token"
  echo "✓ 已保存到 $ROOT/.tools/gh_token（权限 600）"
  echo "  在对话里说「推送」，我会执行：./scripts/push-with-token.sh all"
  exit 0
fi

if ! find_token; then
  echo "✗ 未找到 token。三选一：" >&2
  echo "  1. ./scripts/push-with-token.sh --save-token" >&2
  echo "  2. 写到 ~/.reservoir-token：printf '%s' 'github_pat_xxx' > ~/.reservoir-token && chmod 600 ~/.reservoir-token" >&2
  echo "  3. 临时：GH_TOKEN=github_pat_xxx ./scripts/push-with-token.sh all" >&2
  exit 1
fi
[ -n "$TOKEN" ] || { echo "✗ token 为空" >&2; exit 1; }
check_file_permissions

case "$TOKEN" in
  github_pat_*|ghp_*|gho_*) ;;
  *) echo "⚠ token 前缀不常见，仍会尝试" ;;
esac

detect_proxy

api_get() {
  curl -sS -m 20 \
    -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$1"
}

# 返回 0 表示可读；输出 "full_name push=true/false"
check_repo() {
  local repo="$1" json
  json="$(api_get "$API/repos/$OWNER/$repo")" || return 1
  printf '%s' "$json" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(1)
if "full_name" not in d:
    sys.exit(1)
p = d.get("permissions") or {}
print("%s  push=%s  pull=%s" % (d["full_name"], p.get("push", "?"), p.get("pull", "?")))
' 2>/dev/null
}

echo "→ token 来源：$TOKEN_SOURCE"
PUBLIC_OK=0
PRIVATE_OK=0
if check_repo "reservoir"; then PUBLIC_OK=1; fi
if check_repo "reservoir-private"; then PRIVATE_OK=1; fi

if [ "$MODE" = "check" ]; then
  if [ "$PUBLIC_OK" = "0" ] && [ "$PRIVATE_OK" = "0" ]; then
    echo "✗ 两个仓库都不可访问：token 无效，或未选中仓库，或缺少 Contents: Read"
    exit 1
  fi
  echo "✓ token 可访问至少一个仓库"
  exit 0
fi

if [ "$PUBLIC_OK" = "0" ] && [ "$PRIVATE_OK" = "0" ]; then
  echo "✗ 两个仓库都不可访问，停止" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/reservoir-push.XXXXXX")"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT INT TERM

cat > "$TMP_DIR/askpass.sh" <<'ASKPASS'
#!/bin/sh
case "$1" in
  *sername*) printf '%s\n' "$GH_USER" ;;
  *) printf '%s\n' "$GH_TOKEN" ;;
esac
ASKPASS
chmod 700 "$TMP_DIR/askpass.sh"

# 用临时 askpass，禁用 credential helper，避免 token 落盘
git_net() {
  GIT_ASKPASS="$TMP_DIR/askpass.sh" \
  GIT_TERMINAL_PROMPT=0 \
  GH_USER="$OWNER" \
  GH_TOKEN="$TOKEN" \
  git -c credential.helper= "$@"
}

push_repo() {
  local dir="$1" name="$2" ahead remote_head local_head
  if [ ! -d "$dir/.git" ]; then
    echo "✗ $name 不是 git 仓库：$dir" >&2
    return 1
  fi
  cd "$dir"
  if ! git remote get-url origin >/dev/null 2>&1; then
    echo "✗ $name 未配置 origin" >&2
    return 1
  fi
  if [ -n "$(git status --porcelain)" ]; then
    echo "✗ $name 有未提交改动，先运行 ./scripts/sync.sh 或等 watcher 提交" >&2
    return 1
  fi

  echo "→ $name：检查远端…"
  if ! git_net fetch -q origin main; then
    echo "✗ $name 拉取远端失败：token 无权限或网络不通" >&2
    return 1
  fi

  ahead="$(git rev-list --count origin/main..HEAD)"
  if [ "$ahead" -eq 0 ]; then
    echo "✓ $name 已同步：$(git rev-parse --short HEAD)"
    return 0
  fi

  echo "→ $name：推送 $ahead 个提交…"
  local out
  if ! out="$(git_net push origin main 2>&1)"; then
    printf '%s\n' "$out" | tail -8
    case "$out" in
      *workflow*|*Workflow*) echo "提示：token 需要 Workflows: Read and write" >&2 ;;
      *"protected branch"*|*"non-fast-forward"*|*"fetch first"*) echo "提示：远端已前进，先 git pull --rebase；脚本不会强推" >&2 ;;
      *"Permission"*|*"403"*) echo "提示：token 需要 Contents: Read and write" >&2 ;;
    esac
    return 1
  fi

  git_net fetch -q origin main
  remote_head="$(git rev-parse origin/main)"
  local_head="$(git rev-parse HEAD)"
  if [ "$remote_head" = "$local_head" ]; then
    echo "✓ $name 已推送：$(git rev-parse --short HEAD)"
    return 0
  fi
  echo "⚠ $name 推送后校验不一致：local=$local_head remote=$remote_head" >&2
  return 1
}

RC=0
case "$TARGET" in
  public)
    push_repo "$ROOT" "公开层" || RC=1
    ;;
  private)
    push_repo "$PRIVATE_REPO" "私密层" || RC=1
    ;;
  all)
    push_repo "$ROOT" "公开层" || RC=1
    if [ -d "$PRIVATE_REPO/.git" ]; then
      push_repo "$PRIVATE_REPO" "私密层" || RC=1
    else
      echo "⚠ 私密层目录不存在，跳过：$PRIVATE_REPO" >&2
    fi
    ;;
esac

exit "$RC"
