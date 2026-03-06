#!/bin/bash
#
# Update ACE Record - 更新 ACE 版本记录
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"

init

# 检查参数
if [[ $# -lt 1 ]]; then
    # 尝试从环境变量或最近修改的文件获取信息
    exit 0
fi

# 查找最近创建的帖子
latest_post=$(find "$CONTENT_DIR/published" -name "*.json" -type f -mmin -5 2>/dev/null | head -1)

if [[ -z "$latest_post" ]]; then
    exit 0
fi

# 读取帖子信息
post_id=$(jq -r '.id // empty' "$latest_post" 2>/dev/null)
persona_id=$(jq -r '.persona_id // empty' "$latest_post" 2>/dev/null)
content=$(jq -r '.content // empty' "$latest_post" 2>/dev/null)

if [[ -z "$post_id" ]]; then
    exit 0
fi

# 生成 ACE 记录
content_hash=$(get_content_hash "$content")
version=$(get_next_version "$post_id")
timestamp=$(get_iso_time)

ace_record=$(cat << EOF
{
  "post_id": "$post_id",
  "version": $version,
  "parent_version": null,
  "change_type": "create",
  "content_hash": "$content_hash",
  "created_at": "$timestamp",
  "change_reason": "Auto commit via Claude Code hook"
}
EOF
)

# 保存 ACE 记录
ace_file="$ARCHIVE_DIR/fix/${post_id}_v${version}.json"
write_json_file "$ace_file" "$ace_record"

echo "[ace] Updated record: ${post_id} v${version}"
