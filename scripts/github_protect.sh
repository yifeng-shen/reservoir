#!/usr/bin/env bash
# 为 Reservoir 仓库开启安全配置：
#   1. Secret Scanning + Push Protection
#   2. main 分支 Ruleset（禁止删除、禁止强推、线性历史）
#   3. snapshot/* 标签保护（禁止删除与更新）
#
# 用法：
#   GITHUB_TOKEN=github_pat_xxx ./scripts/github_protect.sh
#   REPO=owner/reservoir GITHUB_TOKEN=... ./scripts/github_protect.sh
#
# 令牌需要 Administration: Read and write 权限。
set -euo pipefail

: "${GITHUB_TOKEN:?请设置 GITHUB_TOKEN 环境变量}"
REPO="${REPO:-yifeng-shen/reservoir}"
API="https://api.github.com/repos/${REPO}"
AUTH=(-H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28")

echo "→ 仓库：${REPO}"

echo "→ 开启 Secret Scanning 与 Push Protection…"
if curl -sS -o /tmp/reservoir-security.json -w '%{http_code}' -X PATCH "${AUTH[@]}" \
  "${API}" \
  -d '{"security_and_analysis":{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}}' \
  | grep -qE '^2'; then
  echo "  ✓ 已开启"
else
  echo "  ⚠ 开启失败（可能需要管理员权限或仓库不支持），继续…"
  head -c 300 /tmp/reservoir-security.json || true
  echo
fi

BRANCH_RULESET='{
  "name": "reservoir-guard",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "required_linear_history" }
  ],
  "bypass_actors": []
}'

TAG_RULESET='{
  "name": "reservoir-tag-guard",
  "target": "tag",
  "enforcement": "active",
  "conditions": {
    "ref_name": { "include": ["refs/tags/snapshot/*"], "exclude": [] }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "update" }
  ],
  "bypass_actors": []
}'

upsert_ruleset() {
  local payload="$1" name="$2"
  local existing_id
  existing_id="$(curl -sS "${AUTH[@]}" "${API}/rulesets" | python3 -c '
import json,sys
name=sys.argv[1]
try:
    data=json.load(sys.stdin)
except Exception:
    data=[]
for item in data:
    if item.get("name")==name:
        print(item.get("id","")); break
' "$name")"

  if [ -n "$existing_id" ]; then
    echo "  → 更新 Ruleset ${name} (id=${existing_id})"
    curl -sS -X PUT "${AUTH[@]}" "${API}/rulesets/${existing_id}" -d "$payload" >/dev/null
  else
    echo "  → 创建 Ruleset ${name}"
    curl -sS -X POST "${AUTH[@]}" "${API}/rulesets" -d "$payload" >/dev/null
  fi
}

echo "→ 配置分支保护（禁止删除 / 强推 / 非线性历史）…"
upsert_ruleset "$BRANCH_RULESET" "reservoir-guard"

echo "→ 配置标签保护（snapshot/*）…"
upsert_ruleset "$TAG_RULESET" "reservoir-tag-guard"

echo "✓ 安全配置完成。查看："
echo "  curl -s ${AUTH[*]} ${API}/rulesets"
